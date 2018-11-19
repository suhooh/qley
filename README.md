# qley
qley is a restaurant search for iOS by Yelp Fusion API.


## How to run
- Clone this repository.
- Go to [Yelp Fusion API](https://www.yelp.com/developers/documentation/v3/get_started) home, and make your own API key.
- Copy the API key and replace `// + "YOUR API KEY HERE"` part with it on line 14 in `YelpAPIService.swift`.

        fileprivate static let APIKey =  APIKeyPrefix // + "YOUR API KEY HERE"
        //
        //
        // Add the API key.
        //
        //
        fileprivate static let APIKey =  APIKeyPrefix + "9L2JW4BCKPcSGuclkmhC... it's long"


- Run & qley

## What you can see in the code
- Yelp Fusion API: Business search, Autocomplete

- MVVM pattern

- RxSwift/RxCocoa

- RxDataSources: two data sources with one table view

- Unit Testing with RxTest/RxBlocking

- MKMapView: Custom annotation, Drawing routes

- Pulley
