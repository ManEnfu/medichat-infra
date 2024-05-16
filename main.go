package main

import (
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/jackc/pgx"
)

func main() {
	var port uint16 = 5432
	if p, err := strconv.Atoi(os.Getenv("PORT")); err == nil {
		port = uint16(p)
	}

	host := "localhost"
	if s := os.Getenv("HOST"); s != "" {
		host = s
	}

	database := "medichat_db"
	if s := os.Getenv("DATABASE"); s != "" {
		database = s
	}

	user := "postgres"
	if s := os.Getenv("USER"); s != "" {
		user = s
	}

	password := ""
	if s := os.Getenv("PASSWORD"); s != "" {
		password = s
	}

	log.Println(port, host, database, user, password)

	pgxConConfig := pgx.ConnConfig{
		Port:     port,
		Host:     host,
		Database: database,
		User:     user,
		Password: password,
	}

	conn, err := pgx.Connect(pgxConConfig)
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	fmt.Println("start Importing ...")

	f, err := os.OpenFile(fmt.Sprintf("%s.csv", "accounts"), os.O_RDONLY, 0777)
	if err != nil {
		return
	}
	fmt.Println("importing from accounts")
	res, err := conn.CopyFromReader(f, fmt.Sprintf("COPY %s(email,email_verified,name,photo_url,role,account_type,hashed_password,profile_set) FROM STDIN DELIMITER ',' CSV HEADER", "accounts"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())
	if err != nil {
		panic(err)
	}
	f.Close()

	fmt.Println("  Done with import accounts")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "pharmacy_managers"), os.O_RDONLY, 0777)
	if err != nil {
		return
	}
	fmt.Println("importing from pharmacy_managers")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(account_id) FROM STDIN DELIMITER ',' CSV HEADER", "pharmacy_managers"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import pharmacy_managers")

	for i := 1; i < 227; i++ {
		f, err := os.OpenFile(fmt.Sprintf("%s.csv", "pharma/pharmacy_"+strconv.Itoa(i)), os.O_RDONLY, 0777)
		if err != nil {
			panic(err)
		}

		fmt.Println("importing from pharmacies" + strconv.Itoa(i))
		res, err := conn.CopyFromReader(f, fmt.Sprintf("COPY %s(name, address, coordinate, pharmacist_name, pharmacist_license, pharmacist_phone, slug, manager_id) FROM STDIN DELIMITER ','", "pharmacies"))
		if err != nil {
			panic(err)
		}
		fmt.Println("==> import rows affected:", res.RowsAffected())

		f.Close()
		fmt.Println("  Done with import pharmacies" + strconv.Itoa(i))

	}

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "shipment_method"), os.O_RDONLY, 0777)
	if err != nil {
		panic(err)
	}
	fmt.Println("importing from shipments")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(pharmacy_id, shipment_method_id) FROM STDIN DELIMITER ',' CSV HEADER", "pharmacy_shipment_methods"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import shipments")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "pharmacy_operations"), os.O_RDONLY, 0777)
	if err != nil {
		panic(err)
	}
	fmt.Println("importing from pharmacy_operations")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(pharmacy_id, day, start_time, end_time) FROM STDIN DELIMITER ',' CSV HEADER", "pharmacy_operations"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import pharmacy_operations")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "category1"), os.O_RDONLY, 0777)
	if err != nil {
		panic(err)
	}

	fmt.Println("importing from categories")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(slug,name,photo_url) FROM STDIN DELIMITER ',' CSV HEADER", "categories"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import categories1")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "category2"), os.O_RDONLY, 0777)
	if err != nil {
		return
	}
	fmt.Println("importing from categories")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(slug,name,photo_url,parent_id) FROM STDIN DELIMITER ',' CSV HEADER", "categories"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import categories2")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "details2"), os.O_RDONLY, 0777)
	if err != nil {
		return
	}
	fmt.Println("importing from details")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(generic_name, content, composition, manufacturer, description, product_classification, product_form, unit_in_pack, selling_unit, weight, height, length, width) FROM STDIN DELIMITER ',' CSV HEADER", "product_details"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import details")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "products2"), os.O_RDONLY, 0777)
	if err != nil {
		panic(err)
	}
	fmt.Println("importing from products")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(category_id, product_detail_id, name, picture, is_active, slug, keyword) FROM STDIN DELIMITER ',' CSV HEADER", "products"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import products")

	f, err = os.OpenFile(fmt.Sprintf("%s.csv", "stocks"), os.O_RDONLY, 0777)
	if err != nil {
		panic(err)
	}
	fmt.Println("importing from stocks")
	res, err = conn.CopyFromReader(f, fmt.Sprintf("COPY %s(product_id, pharmacy_id, stock, price) FROM STDIN DELIMITER ',' CSV HEADER", "stocks"))
	if err != nil {
		panic(err)
	}
	fmt.Println("==> import rows affected:", res.RowsAffected())

	f.Close()
	fmt.Println("  Done with import stocks")

}

// func exporter(conn *pgx.Conn, f *os.File, table string) error {
//     res, err := conn.CopyToWriter(f, fmt.Sprintf("COPY %s TO STDOUT DELIMITER '|' CSV HEADER", table))
//     if err != nil {
//         return fmt.Errorf("error exporting file: %+v", err)
//     }
//     fmt.Println("==> export rows affected:", res.RowsAffected())
//     return nil
// }
