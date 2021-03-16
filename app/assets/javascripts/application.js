// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
// require turbolinks
// require bootstrap-sprockets
//
//= require jquery
//= require jquery-ui.min
//= require rails-ujs
// require jquery.dataTables.min
//= require jquery.dataTables
//= require bootstrap.bundle.min
//= require jquery.scrollTo.min
/*
  ---------------------------------------------
  localize_time method takes time element as argument in string format or HTML element.
  Ex: '<time datetime="2020-09-23T18:12:52Z" data-local="time" data-format="%m/%d/%Y %I:%M:%S%p %Z">09/23/2020 06:12:52PM UTC</time>'
*/
function localize_time(time_element){
  if (time_element && (typeof (time_element) == 'string' || time_element.tagName == 'TIME')){
    element = (typeof(time_element) != 'string' && time_element.tagName == 'TIME') ? time_element : $.parseHTML($.trim(time_element))[0];
    if (element.tagName == 'TIME') {
      datetime = element.getAttribute("datetime");
      format = element.getAttribute("data-format");
      if (datetime && format) {
        time = LocalTime.parseDate(datetime);
        return LocalTime.strftime(time, format);
      }
    }
  }
  return time_element;
}

$(document)
  .ajaxStart(function () {
    if (showLoadingEnabled) {
      $('#overlay').show();
    }
  })
  .ajaxStop(function () {
    if (showLoadingEnabled) {
      $('#overlay').hide();
    }
  });
$( document ).ready(function() {
  $.sessionTimeout({
    keepAliveUrl: '/',
    logoutUrl: "/users/sign_out",
    warnAfter: 3300000,
    redirAfter: 3600000
  });
});
