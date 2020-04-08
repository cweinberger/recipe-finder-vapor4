# Recipe Finder

A recipe search API that allows to manage/search recipes stored in Elasticsearch.

## Install Elasticsearch

### Pull and run the image:

```
docker run -d --name elasticsearch -p 9200:9200 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.6.2.
```
(more: see https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

On the first start this will pull the image and run it; on subsequent starts, it will run the downloaded image.

## Commands

### Delete Index Command

Deletes the index {indexName} from Elasticsearch.

Usage:  `vapor-beta run elastic:deleteIndex {indexName}`

Example:  `vapor-beta run elastic:deleteIndex recipes`

### Import Recipes Command

Imports recipes from a json file within the `Resources` folder into Elasticsearch index `recipes`.

Usage:  `vapor-beta run elastic:importRecipes {fileName}`

Example:  `vapor-beta run elastic:importRecipes /full/path/to/recipes.json`

## Trying out requests

All requests can be tested using `cURL`, or alternatively using the Paw Mac app with the .paw collection `vapor-elasticsearch.paw` in the Download Materials `final` folder.
