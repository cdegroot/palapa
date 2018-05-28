import {Socket} from "phoenix"
import Vue from 'vue'
import MyApp from "../components/my-app.vue"

let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()

Vue.component('my-app', MyApp)

new Vue({
  el: '#app',
  render(createElement) {
    return createElement(MyApp, {})
  }
});

// Now that you are connected, you can join channels with a topic:
//let channel = socket.channel("topic:subtopic", {})
//channel.join()
  //.receive("ok", resp => { console.log("Joined successfully", resp) })
  //.receive("error", resp => { console.log("Unable to join", resp) })

//export default socket
