<template>
  <div id="app">
    <a-input-search
        placeholder="Search"
        enter-button="Search"
        size="large"
        @search="onSearch"
    />
    <div v-if="suggested===true">
      {{'(Suggestion Below)'}}
      <ul>
        <li v-bind:key="item.text" v-for="item in this.suggestion">
          {{item.text + '\t' + item.score + '\t' + item.freq}}
        </li>
      </ul>
    </div>

    <a-list item-layout="vertical" size="large" :data-source="results">
      <a-list-item slot="renderItem" key="item.title + " slot-scope="item">
        <img
            v-if="results.length > 0"
            slot="extra"
            width="272"
            alt="logo"
            :src=item._source.image_link
        />
        <a-list-item-meta :description="item._source.second_category + item._source.third_category">
          <a slot="title">{{ item._source.title }}</a>
        </a-list-item-meta>
        <div style="margin: 0 auto; width:600px;" class="itemId">{{ "item_id: " + item._source.item_id | ellipsis }}</div>
      </a-list-item>
    </a-list>

  </div>
</template>

<script>
export default {
  name: 'App',
  components: {
  },
  data() {
    return {
      // url: 'http://es-nlb.dynamic-ads.smartnews.net:9200/test-1/_search',
      url: 'http://localhost:8888/test-1/_search',
      hits: 0,
      results: [],
      suggested: false,
      suggestion: [],
    }
  },
  filters:{
    ellipsis(value){
      if (!value) return '';
      if (value.length > 100) {
        return value.slice(0,100) + '...'
      }
      return value
    }
  },
  methods: {
    onSearch(value) {
      this.suggested = false
      // let query = {
      //   "query": {
      //     "match": {
      //       "title": {
      //         "query": value,
      //         "minimum_should_match": "80%",
      //          //"operator": "and"
      //       }
      //     },
      //   }
      // };
      let query = {
        "query": {
          "bool": {
            "must": [
              {
                "match":
                    {
                      "title": {
                        "query": value,
                        "minimum_should_match": "90%"
                      }
                    },
              },
              {
                "match":
                    {
                      "title.ngram": {
                        "query": value,
                        "minimum_should_match": "90%"
                      }
                    },
              }
            ],
            "should": [
              {
                "match": {
                  "second_category": {
                    "query": value,
                    "operator": "and"
                  }
                }
              },
              {
                "match": {
                  "third_category": {
                    "query": value,
                    "operator": "and"
                  }
                }
              }
            ]
          }
        }
      };
      this.axios.get(this.url, {
        params: {
          source: JSON.stringify(query),
          source_content_type: 'application/json'
        }
      }).then((response) => {
        console.log(response.data.hits.total['value'])
        this.hits = response.data.hits.total['value']
        this.results = response.data.hits.hits
        // if need suggestion
        if(this.results == null || this.results.length === 0) {
          this.suggested = true
          let suggestionQuery = {
            "suggest": {
              "text" : value,
              "title_suggest" : {
                "term" : {
                  "field" : "title"
                }
              }
            }
          };
          this.axios.get(this.url, {
            params: {
              source: JSON.stringify(suggestionQuery),
              source_content_type: 'application/json'
            }
          }).then((res) => {
            this.suggestion = JSON.parse(JSON.stringify(res.data.suggest.title_suggest[0].options))
            console.log(this.suggestion)
          }).catch(function (err) {
            console.log(err);
          })
        }
      }).catch(function (error) {
        console.log(error);
      })
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
