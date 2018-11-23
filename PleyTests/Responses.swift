import Foundation

class Response {
    // swiftlint:disable line_length
    static let autocompleteResponseJsonString = """
{\n  \"categories\" : [\n    {\n      \"alias\" : \"sushi\",\n      \"title\" : \"Sushi Bars\"\n    },\n    {\n      \"alias\" : \"conveyorsushi\",\n      \"title\" : \"Conveyor Belt Sushi\"\n    },\n    {\n      \"alias\" : \"japanese\",\n      \"title\" : \"Japanese\"\n    }\n  ],\n  \"businesses\" : [\n\n  ],\n  \"terms\" : [\n    {\n      \"text\" : \"Sushi\"\n    },\n    {\n      \"text\" : \"Sushi Delivery\"\n    },\n    {\n      \"text\" : \"Sushi Restaurant\"\n    }\n  ]\n}
"""

    static let businessSearchResponseJsonString = """
{\n  \"region\" : {\n    \"center\" : {\n      \"longitude\" : 13.510005547510879,\n      \"latitude\" : 52.457187426202253\n    }\n  },\n  \"businesses\" : [\n    {\n      \"phone\" : \"+493063418380\",\n      \"id\" : \"JAPNGA8x-MuzrENhl1V3bg\",\n      \"price\" : \"€€\",\n      \"coordinates\" : {\n        \"longitude\" : 13.5112986713648,\n        \"latitude\" : 52.457935560092999\n      },\n      \"categories\" : [\n        {\n          \"alias\" : \"sushi\",\n          \"title\" : \"Sushi Bars\"\n        }\n      ],\n      \"name\" : \"Funa Sushi\",\n      \"alias\" : \"funa-sushi-berlin\",\n      \"rating\" : 3.5,\n      \"display_phone\" : \"+49 30 63418380\",\n      \"image_url\" : \"https:\\/\\/s3-media3.fl.yelpcdn.com\\/bphoto\\/yafrYmXC4gqUZJT5KeTlKQ\\/o.jpg\",\n      \"url\" : \"https:\\/\\/www.yelp.com\\/biz\\/funa-sushi-berlin?adjust_creative=rh_zR616T1KQfDJw-L_Ejg&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_search&utm_source=rh_zR616T1KQfDJw-L_Ejg\",\n      \"location\" : {\n        \"display_address\" : [\n          \"Brückenstr. 27\",\n          \"12439 Berlin\",\n          \"Germany\"\n        ],\n        \"zip_code\" : \"12439\",\n        \"city\" : \"Berlin\",\n        \"country\" : \"DE\",\n        \"address1\" : \"Brückenstr. 27\",\n        \"address3\" : \"\",\n        \"state\" : \"BE\",\n        \"address2\" : \"\"\n      },\n      \"is_closed\" : false,\n      \"distance\" : 120.81871516444706,\n      \"transactions\" : [\n\n      ],\n      \"review_count\" : 5\n    }\n  ],\n  \"total\" : 1\n}
"""
    // swiftlint:enable line_length
}
