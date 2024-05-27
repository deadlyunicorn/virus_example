import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main() async {
  while (true) {
    try {
      final http.Response res = await http.get(
        Uri.parse(
          "http://localhost:8080/api/command",
        ),
      );

      if (res.statusCode == 404) {
        try {
          throw ResourceNotFoundException(message: "404 - Not found.");
        } on ResourceNotFoundException catch (error) {
          print(error.message);
        }
      } else {
        final ServerCommandExecutionObject fullCommand =
            ServerCommandExecutionObject.fromJson(
          jsonDecode(res.body),
        );

        print("command: ${fullCommand.command}");
        print("arguments: ${fullCommand.arguments}");

        await Process.run(fullCommand.command, fullCommand.arguments).then(
          (ProcessResult processResult) {
            print("Command result: ${processResult.stdout}");
            print("Errors: ${processResult.stderr}");
          },
        );
      }
    } on http.ClientException {
      bool isCompleted = false;
      final Duration delayBeforeRetrying = Duration(seconds: 10);
      unawaited(
        Future<void>.delayed(delayBeforeRetrying).whenComplete(
          () {
            isCompleted = true;
          },
        ),
      );
      final DateTime timeStampOfRetrying = DateTime.now().add(
        delayBeforeRetrying,
      );
      stdout.write(
        "\rServer did not respond (${DateTime.now().toLocal()})."
        " Are you connected to the internet?\n",
      );

      while (!isCompleted) {
        {
          stdout.write(
            // ignore: prefer_interpolation_to_compose_strings
            "\rRetrying in " +
                timeStampOfRetrying
                    .difference(DateTime.now())
                    .inSeconds
                    .toString() +
                " seconds.".padRight(48, ' '),
          );
          await Future<void>.delayed(Duration(seconds: 1));
        }
      }

      print("");
    }

    await Future<void>.delayed(Duration(seconds: 5));
  }
}

class ServerCommandExecutionObject {
  String command;
  List<String> arguments;

  ServerCommandExecutionObject({
    required this.command,
    required this.arguments,
  });

  ServerCommandExecutionObject.fromJson(Map<String, dynamic> json)
      : command = json['command'].toString(),
        arguments = json['arguments'].toString().split(" ");

  Map<String, dynamic> toJson() => <String, dynamic>{
        'command': command,
        'arguments': arguments.join(" "),
      };
}

class ResourceNotFoundException implements Exception {
  final String message;
  ResourceNotFoundException({
    required this.message,
  });
}
