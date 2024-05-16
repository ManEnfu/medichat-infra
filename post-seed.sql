\c medichat_db;

CREATE TRIGGER set_slug_from_product_name
BEFORE INSERT OR UPDATE
ON "products"
FOR EACH ROW
EXECUTE FUNCTION public.set_slug_from_product_name();

CREATE TRIGGER set_slug_from_name
BEFORE INSERT OR UPDATE
ON "pharmacies"
FOR EACH ROW
EXECUTE FUNCTION public.set_slug_from_name();
