import firebase_admin
from firebase_admin import credentials, firestore

def main():
    # 1. Carga las credenciales de tu proyecto Firebase
    cred = credentials.Certificate("./xarhani-99f05-firebase-adminsdk-fbsvc-13b6f05cd2.json")
    firebase_admin.initialize_app(cred)

    # 2. Obtén la referencia al cliente de Firestore
    db = firestore.client()

    # -----------------------------
    # Ejemplo: Creación de "states"
    # -----------------------------
    state_data = {
        "state_name": "Example State"
    }
    # Document ID manual (ej: "state_id_1") o puedes usar db.collection("states").add(state_data)
    state_ref = db.collection("states").document("state_id_1")
    state_ref.set(state_data)

    # -----------------------------
    # Ejemplo: Creación de "cities"
    # -----------------------------
    city_data = {
        "city_name": "Example City",
        "state_id": state_ref.id  # Guardamos el ID de "state_id_1" o podrías usar "state_ref" como referencia
    }
    city_ref = db.collection("cities").document("city_id_1")
    city_ref.set(city_data)

    # -----------------------------
    # Ejemplo: Creación de "categories"
    # -----------------------------
    category_data = {
        "category_name": "Restaurant"
    }
    category_ref = db.collection("categories").document("category_id_1")
    category_ref.set(category_data)

    # -----------------------------
    # Ejemplo: Creación de "commerces"
    # -----------------------------
    commerce_data = {
        "commerce_name": "Example Commerce",
        "commerce_location": "Some location",
        "commerce_phone": "1234567890",
        "city_id": city_ref.id,    # referenciamos la ciudad
        "state_id": state_ref.id,  # referenciamos el estado
        "categories": [category_ref.id]  # arreglo de IDs de categorías
    }
    commerce_ref = db.collection("commerces").document("commerce_id_1")
    commerce_ref.set(commerce_data)

    # Subcolección "owners" dentro de un comercio
    owner_data = {
        "owner_name": "John Owner",
        "owner_email": "john.owner@example.com"
    }
    # Creamos el documento dentro de la subcolección
    owner_ref = commerce_ref.collection("owners").document("owner_id_1")
    owner_ref.set(owner_data)

    # Subcolección "schedules" dentro de un comercio
    schedule_data = {
        "day_of_week": 1,
        "opening_time": "08:00",
        "closing_time": "18:00"
    }
    schedule_ref = commerce_ref.collection("schedules").document("schedule_id_1")
    schedule_ref.set(schedule_data)

    # Subcolección "products" dentro de un comercio
    product_data = {
        "product_name": "Example Product"
    }
    product_ref = commerce_ref.collection("products").document("product_id_1")
    product_ref.set(product_data)

    # Subcolección "presentations" dentro de un producto
    presentation_data = {
        "presentation_name": "Small",
        "price": 9.99
    }
    presentation_ref = product_ref.collection("presentations").document("presentation_id_1")
    presentation_ref.set(presentation_data)

    # -----------------------------
    # Ejemplo: Creación de "users"
    # -----------------------------
    user_data = {
        "user_name": "Alice",
        "user_email": "alice@example.com",
        "user_password": "secure_hash",
        # Ej: Guardamos los comercios que le gustan como arreglo de IDs o referencias
        "liked_commerces": [commerce_ref.id]
    }
    user_ref = db.collection("users").document("user_id_1")
    user_ref.set(user_data)

    print("Datos agregados exitosamente a Firestore.")

if __name__ == "__main__":
    main()
