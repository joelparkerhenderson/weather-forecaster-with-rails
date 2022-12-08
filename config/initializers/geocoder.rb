Geocoder.configure(
    esri: {
        api_key: [
            Rails.application.credentials.arcgis_api_user_id, 
            Rails.application.credentials.arcgis_api_secret_key,
        ], 
        for_storage: true
    }
)
