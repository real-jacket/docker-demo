<template>
  <div class="home">
    <img alt="Vue logo" src="../assets/logo.png">
    <HelloWorld msg="Hello Docker"/>
  </div>
</template>

<script>
// @ is an alias to /src
import HelloWorld from "@/components/HelloWorld.vue";
import axios from "axios";

export default {
  name: "home",
  components: {
    HelloWorld
  },
  created() {
    axios
      .get("/api/json", {
        params: {}
      })
      .then(res => {
        console.log(res);
      })
      .catch(err => {
        console.log(err);
      });
  }
};
</script>
