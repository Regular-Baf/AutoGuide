import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _locationMessage = '';
  String _responseMessage = '';
  String _apiUrl = 'http://localhost:1234/v1/completions'; // initialize with the default value

  final _apiUrlController = TextEditingController();
  final _responseController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize the _apiUrlController with the default value
    _apiUrlController.text = _apiUrl;

    // Add a listener to the _apiUrlController to update _apiUrl when the text changes
    _apiUrlController.addListener(() {
      setState(() {
        _apiUrl = _apiUrlController.text;
      });
    });

    // Add a listener to the _apiUrlController to update _apiUrl when the text changes
    _apiUrlController.addListener(() {
      setState(() {
        _apiUrl = _apiUrlController.text;
      });
    });
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Check if the API URL is valid
    try {
      final uri = Uri.parse(_apiUrl);
      if (uri.scheme.isEmpty || uri.host.isEmpty) {
        throw FormatException('Invalid API URL');
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: Invalid API URL';
        _responseController.text = 'Error: Invalid API URL';
        _isLoading = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationMessage = "${position.latitude}, ${position.longitude}";
      });

      // Create a JSON object with the prompt
      var jsonData = {
        "prompt": "Get location-based information for ${position.latitude}, ${position.longitude}",
        "stream": true,
        "max_tokens": 5,
        "temperature": 0.5,
        "top_p": 0.9
      };

      // Convert the JSON object to a string
      var jsonString = jsonEncode(jsonData);

      // Set the API endpoint URL and headers
      var url = Uri.parse(_apiUrl); // use the user-input API URL
      var headers = {
        'Content-Type': 'application/json',
      };

      // Send the POST request
      var response = await http.post(url, headers: headers, body: jsonString);

// Check the response status code
      if (response.statusCode == 200) {
        // If the response is successful, print the response body for debugging
        print('Response body: ${response.body}');

        // Remove the "data: " prefix and parse the JSON
        var responseBody = response.body.substring(6);
        try {
          var jsonResponse = jsonDecode(responseBody);

          // Extract the 'choices' array and process the response
          var choicesArray = jsonResponse['choices'];
          if (choicesArray != null && choicesArray.length > 0) {
            var choice = choicesArray[0];
            var choiceText = choice['text'];
            setState(() {
              _responseMessage = choiceText;
              _responseController.text = choiceText; // update the response TextField
              _isLoading = false;
            });
          }
        } catch (e) {
          // If the response cannot be parsed as JSON, print an error message
          print('Error parsing JSON: $e');
          setState(() {
            _responseMessage = 'Error parsing JSON: $e';
            _responseController.text = 'Error parsing JSON: $e'; // update the response TextField
            _isLoading = false;
          });
        }
      } else {
        // If the response is not successful, print the error message
        print('Error: ${response.statusCode}'); // Debugging print statement
        setState(() {
          _responseMessage = 'Error: ${response.statusCode}';
          _responseController.text = 'Error: ${response.statusCode}'; // update the response TextField
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e'); // Debugging print statement for exceptions
      setState(() {
        _responseMessage = 'Error: $e';
        _responseController.text = 'Error: $e'; // update the response TextField
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Where am I?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // add padding to the sides
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Press the button to get your current location:',
            ),
            Center(
              child: Text(
                _locationMessage,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Add a TextField to display the response
            TextField(
              controller: _responseController,
              maxLines: 5,
              enabled: true, // make the text field not editable
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Response',
              ),
            ),
            if (_isLoading)
              CircularProgressIndicator(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0), // add padding to the sides
        child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiUrlController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'API URL',
                  ),
                ),
              ),
            ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Send Location to API',
        child: const Icon(Icons.location_on),
      ),
    );
  }
}