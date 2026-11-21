create table public.roles (
  id smallint primary key,
  name text not null unique
);

insert into public.roles (id, name) values (1, 'admin'), (2, 'customer');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role_id smallint not null default 2 references public.roles (id),
  created_at timestamptz not null default now()
);

create table public.categories (
  id bigint generated always as identity primary key,
  name text not null unique
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  description text,
  price numeric(10, 2) not null check (price >= 0),
  stock integer not null check (stock >= 0),
  category_id bigint references public.categories (id) on delete set null,
  image_url text,
  created_at timestamptz not null default now()
);

create table public.orders (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id),
  total numeric(12, 2) not null default 0,
  status text not null default 'pending' check (status in ('pending', 'done', 'cancelled')),
  created_at timestamptz not null default now()
);

create table public.order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  product_name text not null,
  unit_price numeric(10, 2) not null,
  quantity integer not null check (quantity > 0)
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role_id = 1
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role_id)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    2
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.place_order(items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  new_order_id bigint;
  order_total numeric(12, 2) := 0;
  line jsonb;
  prod public.products%rowtype;
  qty integer;
begin
  if uid is null then
    raise exception 'You must be signed in to place an order';
  end if;

  if public.is_admin() then
    raise exception 'Admins cannot place orders';
  end if;

  if items is null or jsonb_typeof(items) <> 'array' or jsonb_array_length(items) = 0 then
    raise exception 'Your cart is empty';
  end if;

  insert into public.orders (user_id, total, status)
  values (uid, 0, 'pending')
  returning id into new_order_id;

  for line in select * from jsonb_array_elements(items)
  loop
    qty := (line ->> 'quantity')::integer;

    if qty is null or qty <= 0 then
      raise exception 'Invalid quantity in cart';
    end if;

    select * into prod
    from public.products
    where id = (line ->> 'product_id')::uuid
    for update;

    if not found then
      raise exception 'A product in your cart no longer exists';
    end if;

    if prod.stock < qty then
      raise exception 'Not enough stock for %', prod.name;
    end if;

    update public.products set stock = stock - qty where id = prod.id;

    insert into public.order_items (order_id, product_id, product_name, unit_price, quantity)
    values (new_order_id, prod.id, prod.name, prod.price, qty);

    order_total := order_total + (prod.price * qty);
  end loop;

  update public.orders
  set total = order_total, status = 'done'
  where id = new_order_id;

  return jsonb_build_object('order_id', new_order_id, 'total', order_total);
end;
$$;

revoke execute on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

alter table public.roles enable row level security;
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;

grant select on public.roles to authenticated;
grant select on public.profiles to authenticated;
grant update (full_name) on public.profiles to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select on public.orders to authenticated;
grant update (status) on public.orders to authenticated;
grant select on public.order_items to authenticated;
grant usage, select on all sequences in schema public to authenticated;

create policy roles_read on public.roles
for select to authenticated
using (true);

create policy profiles_read_own_or_admin on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_admin());

create policy profiles_update_own on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy categories_read on public.categories
for select to authenticated
using (true);

create policy categories_admin_insert on public.categories
for insert to authenticated
with check (public.is_admin());

create policy categories_admin_update on public.categories
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy categories_admin_delete on public.categories
for delete to authenticated
using (public.is_admin());

create policy products_read on public.products
for select to authenticated
using (true);

create policy products_admin_insert on public.products
for insert to authenticated
with check (public.is_admin());

create policy products_admin_update on public.products
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy products_admin_delete on public.products
for delete to authenticated
using (public.is_admin());

create policy orders_read_own_or_admin on public.orders
for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy orders_admin_update_status on public.orders
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy order_items_read_own_or_admin on public.order_items
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.orders o
    where o.id = order_items.order_id and o.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy product_images_read on storage.objects
for select to authenticated
using (bucket_id = 'product-images');

create policy product_images_admin_insert on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and public.is_admin());

create policy product_images_admin_update on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and public.is_admin());

create policy product_images_admin_delete on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and public.is_admin());

insert into public.categories (name) values
  ('Hot Coffee'),
  ('Cold Brew'),
  ('Pastries'),
  ('Coffee Beans');
