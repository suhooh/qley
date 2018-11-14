# qley
qley is a restaurant search for iOS by Yelp Fusion API.

It uses MVVM pattern with RxSwift.

### How to run
- Clone this repository.
- Go to [Yelp Fusion API](https://www.yelp.com/developers/documentation/v3/get_started) home, and make your own API key.
- Copy the API key and paste it by replacing `// + "YOUR API KEY HERE"` on line 12 in `YelpAPIService.swift`.

        fileprivate static let APIKey =  APIKeyPrefix // + "YOUR API KEY HERE"
        
        // change it like this e.g.

        fileprivate static let APIKey =  APIKeyPrefix + "9L2JW4BCKPcSGuclkmhC... it's long"


- Run & qley

