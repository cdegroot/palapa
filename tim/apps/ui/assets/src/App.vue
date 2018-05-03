<template>
  <main>
    <b-navbar toggleable="md" type="dark" variant="primary">
      <b-navbar-toggle target="nav_collapse"></b-navbar-toggle>
      <b-navbar-brand href="#">Thermostat, IMproved</b-navbar-brand>
      <b-collapse is-nav id="nav_collapse">
        <!-- Right aligned nav items -->
        <b-navbar-nav class="ml-auto">
          <b-nav-item href="#">Link</b-nav-item>
          <b-nav-item href="#" disabled>Disabled</b-nav-item>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>
    <b-container class="main-row">
      <b-row>
        <b-col>
          <hello></hello>
        </b-col>
      </b-row>
    </b-container>
  </main>
</template>

<script>
  import Hello from './components/Hello'
  export default {
    name: 'app',
    components: {
      Hello
    }
  }
</script>

<style>
  body {
    font-family: 'Avenir', Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    color: #2c3e50;
  }
  main {
    margin-top: 0px;
  }
</style>
