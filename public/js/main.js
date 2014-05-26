'use strict';

var fontexpert = angular
  .module('fontexpert', [
    'ngRoute',
    'angularFileUpload',
    'angularTreeview'
  ])
  .config(function ($routeProvider) {
    $routeProvider
      .when('/', {
        templateUrl: 'views/upload.html',
        controller: 'UploadCtrl'
      })
      .when('/:session_id', {
        templateUrl: 'views/view.html',
        controller: 'ViewCtrl'
      });
  });


fontexpert.controller('UploadCtrl', function($scope, $upload, $rootScope, $location) {
  $rootScope.psdData = {};
  $scope.onFileSelect = function($files) {
    //$files: an array of files selected, each file has name, size, and type.
    for (var i = 0; i < $files.length; i++) {
      var file = $files[i];
      $scope.upload = $upload.upload({
        url: '/api', //upload.php script, node.js route, or servlet url
        // method: 'POST' or 'PUT',
        // headers: {'header-key': 'header-value'},
        // withCredentials: true,
        data: {myObj: $scope.myModelObj},
        file: file, // or list of files: $files for html5 only
        /* set the file formData name ('Content-Desposition'). Default is 'file' */
        //fileFormDataName: myFile, //or a list of names for multiple files (html5).
        /* customize how data is added to formData. See #40#issuecomment-28612000 for sample code */
        //formDataAppender: function(formData, key, val){}
      }).progress(function(evt) {
        $scope.uploadPercent = parseInt(100.0 * evt.loaded / evt.total);
      }).success(function(data, status, headers, config) {
        // file is uploaded successfully
        $rootScope.psdData = data;
        $location.path('/' + data.session_id);
      });
      //.error(...)
      //.then(success, error, progress); 
      //.xhr(function(xhr){xhr.upload.addEventListener(...)})// access and attach any event listener to XMLHttpRequest.
    }
    /* alternative way of uploading, send the file binary with the file's content-type.
       Could be used to upload files to CouchDB, imgur, etc... html5 FileReader is needed. 
       It could also be used to monitor the progress of a normal http post/put request with large data*/
    // $scope.upload = $upload.http({...})  see 88#issuecomment-31366487 for sample code.
  };
});


fontexpert.controller('ViewCtrl', function($scope, $rootScope, $routeParams, $http) {
  if(!($rootScope.psdData && $rootScope.psdData.session_id === $routeParams.session_id)) {
    $http({method: 'GET', url: '/api/' + $routeParams.session_id }).
      success(function(data, status, headers, config) {
        $rootScope.psdData = data
      }).
      error(function(data, status, headers, config) {
        
      });
  }
});

fontexpert.controller('ListCtrl', function($scope, $rootScope) {
  $rootScope.$watch('psdData', function() {
    if($rootScope.psdData) {
      $scope.layers = $rootScope.psdData.layer_data.layers;
      $scope.mergedLayers = mergeLayers();
    }
  });

  var mergeLayers = function() {
    var allLayers = $rootScope.psdData.layer_data.layers;

    var mergedLayers = _.chain(allLayers)
      .pluck('text')
      .flatten()
      .groupBy(function(obj) {
        return (obj.font_info['font-size']  + obj.font_info['font-family'] + obj.font_info.color)
      })     
      .toArray()
      .sortBy(function(layer) { return layer[0].font_info['font-size'] }) 
      .reverse()
      .value()  
    return mergedLayers;
  }
});

fontexpert.filter('reverse', function() {
  return function(items) {
    console.log(items);
    return items.slice().reverse();
  };
});

