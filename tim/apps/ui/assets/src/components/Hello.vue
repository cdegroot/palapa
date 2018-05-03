<template>
  <div>
    <p>Outside temp: {{outside_temp}}&deg;C</p>
  </div>
</template>

<script>
  import {Socket} from "phoenix"
  let socket = new Socket("/socket", {params: {token: window.userToken}})
  socket.connect()

  export default {
    name: 'thermostat',
    mounted() {
      this.channel = socket.channel("thermostat", {});
      this.channel.on("new_msg", payload => {
        this.outside_temp = payload.outside_temp;
      });
      this.channel.join()
        .receive("ok", response => { console.log("Joined successfully", response) })
        .receive("error", response => { console.log("Unable to join", response) })
    },
    data() {
      return {
        channel: null,
        outside_temp: -273.15
      }
    }
  }
</script>

<style scoped>
    p {
        margin-top: 40px;
    }
</style>
