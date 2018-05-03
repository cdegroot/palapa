import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import App from './App'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import './global.css'

import {Socket} from "phoenix"

Vue.use(BootstrapVue)

let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()

Vue.config.productionTip = false

new Vue({
  el: '#app',
  template: '<App/>',
  components: { App }
})
