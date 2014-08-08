module.exports = (grunt) ->

  grunt.initConfig

    pkg: grunt.file.readJSON "package.json"

    coffee:
      def:
        expand: true
        src: ["src/**/*.coffee"]
        ext: ".js"
        extDot: "last"

    watch:
      scripts:
        files: ["**/*.coffee"]
        tasks: ["coffee"]
        options:
          spawn: false


  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"

  grunt.registerTask "default", ["coffee"]
