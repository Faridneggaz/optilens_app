import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/data/mappers/task_mappers.dart';
import 'package:optilens/data/repositories/task_repository.dart';
import 'package:optilens/domain/entities/attachment_photo.dart';
import 'package:optilens/domain/entities/task.dart';
import 'package:optilens/domain/failures/failures.dart';

http.Response response(Map<String, dynamic> value) => http.Response(
  jsonEncode({'message': value}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'Task list calls the new API with SID, scope and server filters',
    () async {
      final repo = TaskRepositoryImpl(
        ApiClient(
          httpClient: MockClient((request) async {
            expect(request.url.path, endsWith('mobile_app.api.get_tasks'));
            expect(request.url.queryParameters, containsPair('token', 'sid'));
            expect(
              request.url.queryParameters,
              containsPair('scope', 'accessible'),
            );
            expect(
              request.url.queryParameters,
              containsPair('status', 'Pending Review'),
            );
            expect(request.url.queryParameters, containsPair('offset', '20'));
            return response({
              'user': 'a@example.com',
              'date': '2026-10-21',
              'can_create': false,
              'summary': {'total_items': 45, 'pending_review_count': 45},
              'has_more': true,
              'tasks': [
                {
                  'name': 'TASK-1',
                  'subject': 'Review',
                  'status': 'Pending Review',
                },
              ],
            });
          }),
        ),
      );
      final result = await repo.fetchTasks(
        token: 'sid',
        scope: 'accessible',
        status: 'Pending Review',
        offset: 20,
      );
      expect(result.tasks.single.subject, 'Review');
      expect(result.summary.totalItems, 45);
      expect(result.summary.pendingReviewCount, 45);
      expect(result.hasMore, isTrue);
      expect(result.canCreate, isFalse);
    },
  );

  test('Task mapper preserves multiple assignees and closure history', () {
    final task = ErpTaskMapper.fromJson({
      'name': 'TASK-1',
      'subject': 'Inventory',
      'description': '<p>Check stock</p>',
      'priority': 'Urgent',
      'type': 'Maintenance',
      'status': 'Working',
      'progress': 35.5,
      'can_write': 1,
      'allowed_statuses': ['Working', 'Completed'],
      'assignees': [
        {'name': 'a@example.com', 'full_name': 'Alice'},
        {'name': 'b@example.com', 'full_name': 'Bob'},
      ],
      'previous_assignees': [
        {'name': 'c@example.com', 'full_name': 'Charlie'},
      ],
    });
    expect(task.descriptionText, 'Check stock');
    expect(task.description, '<p>Check stock</p>');
    expect(task.assignees.map((a) => a.displayName), ['Alice', 'Bob']);
    expect(task.previousAssignees.single.displayName, 'Charlie');
    expect(task.priority, 'Urgent');
    expect(task.type, 'Maintenance');
    expect(task.progress, 35.5);
    expect(task.canWrite, isTrue);
  });

  test('create Task posts native fields and several User names', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, endsWith('mobile_app.api.create_task'));
          final body = jsonDecode(request.body) as Map;
          expect(body['assignees'], ['a@example.com', 'b@example.com']);
          expect(body['subject'], 'Inventory');
          expect(body['priority'], 'Urgent');
          expect(body['exp_end_date'], '2026-10-22');
          expect(body['description'], 'A &lt; B<br>Next');
          expect(body['type'], 'Maintenance');
          expect(body.containsKey('project'), isFalse);
          expect(body.containsKey('allocated_to'), isFalse);
          return response({
            'success': true,
            'task': {'name': 'TASK-1', 'subject': 'Inventory'},
          });
        }),
      ),
    );
    final saved = await repo.createTask(
      token: 'sid',
      input: const TaskInput(
        subject: ' Inventory ',
        description: 'A < B\nNext',
        priority: 'Urgent',
        type: 'Maintenance',
        endDate: '2026-10-22',
        assignees: ['a@example.com', 'b@example.com'],
      ),
    );
    expect(saved.name, 'TASK-1');
  });

  test('creating a Task sends the voice note with the task fields', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('mobile_app.api.create_task'));
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          expect(request.body, contains('name="subject"\r\n\r\nInventory'));
          expect(
            request.body,
            contains('name="voice"; filename="note-vocale.wav"'),
          );
          expect(request.body, contains('RIFF'));
          expect(request.body, isNot(contains('name="photo"')));
          return response({
            'success': true,
            'task': {'name': 'TASK-1', 'subject': 'Inventory'},
          });
        }),
      ),
    );
    final saved = await repo.createTask(
      token: 'sid',
      input: TaskInput(
        subject: 'Inventory',
        voiceRecording: Uint8List.fromList(ascii.encode('RIFF')),
      ),
    );
    expect(saved.name, 'TASK-1');
  });

  test(
    'fetching a Task exposes its saved OGG voice and preserves the format',
    () async {
      final audio = ascii.encode('OggS');
      final repo = TaskRepositoryImpl(
        ApiClient(
          httpClient: MockClient((request) async {
            if (request.method == 'GET') {
              expect(request.url.path, endsWith('mobile_app.api.get_task'));
              return response({
                'task': {
                  'name': 'TASK-1',
                  'subject': 'Inventory',
                  'voice_ids': ['FILE-1'],
                },
              });
            }
            expect(request.url.path, endsWith('mobile_app.api.get_task_voice'));
            expect(request.headers['accept'], contains('audio/ogg'));
            expect(jsonDecode(request.body), {
              'token': 'sid',
              'name': 'TASK-1',
              'file_id': 'FILE-1',
            });
            return http.Response.bytes(
              audio,
              200,
              headers: {'content-type': 'audio/ogg'},
            );
          }),
        ),
      );
      final detail = await repo.fetchTaskDetail(token: 'sid', name: 'TASK-1');
      expect(detail.task.voiceIds, ['FILE-1']);
      final recording = await repo.fetchVoice(
        token: 'sid',
        taskName: detail.task.name,
        fileId: detail.task.voiceIds.single,
      );
      expect(recording.mimeType, 'audio/ogg');
      expect(recording.bytes, audio);
    },
  );

  test(
    'task edits send new photos and voice removals in one request',
    () async {
      var requests = 0;
      final repo = TaskRepositoryImpl(
        ApiClient(
          httpClient: MockClient((request) async {
            requests++;
            expect(request.url.path, endsWith('mobile_app.api.update_task'));
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data;'),
            );
            expect(
              request.body,
              contains('name="photo"; filename="first.jpg"'),
            );
            expect(
              request.body,
              contains('name="photo"; filename="second.png"'),
            );
            expect(request.body, contains('name="modified"\r\n\r\nversion-1'));
            expect(request.body, contains('name="token"\r\n\r\nsid'));
            expect(
              request.body,
              contains('name="removed_voice_ids"\r\n\r\n["VOICE-1"]'),
            );
            expect(
              request.body,
              contains('name="assignees"\r\n\r\n["a@example.com"]'),
            );
            return response({
              'success': true,
              'task': {'name': 'TASK-1', 'subject': 'Inventory'},
            });
          }),
        ),
      );

      await repo.updateTask(
        token: 'sid',
        name: 'TASK-1',
        modified: 'version-1',
        input: TaskInput(
          subject: 'Inventory',
          assignees: const ['a@example.com'],
          removedVoiceIds: const ['VOICE-1'],
          photos: [
            SelectedPhoto(name: 'first.jpg', bytes: Uint8List.fromList([1])),
            SelectedPhoto(name: 'second.png', bytes: Uint8List.fromList([2])),
          ],
        ),
      );

      expect(requests, 1);
    },
  );

  test('edit preserves unchanged rich text and closed assignments', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('mobile_app.api.update_task'));
          final body = jsonDecode(request.body) as Map;
          expect(body['modified'], 'version-1');
          expect(body.containsKey('description'), isFalse);
          expect(body.containsKey('assignees'), isFalse);
          expect(body.containsKey('project'), isFalse);
          expect(body, containsPair('type', ''));
          expect(body['progress'], 35.5);
          return response({
            'success': true,
            'task': {'name': 'TASK-1', 'subject': 'Inventory'},
          });
        }),
      ),
    );
    await repo.updateTask(
      token: 'sid',
      name: 'TASK-1',
      modified: 'version-1',
      input: const TaskInput(
        subject: 'Inventory',
        progress: 35.5,
        updateAssignments: false,
        type: '',
      ),
    );
  });

  test('searches native Task Types through Task options', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('mobile_app.api.get_task_options'));
          expect(request.url.queryParameters, containsPair('kind', 'types'));
          expect(request.url.queryParameters, containsPair('search_text', 'maint'));
          return response({'success': true, 'types': ['Maintenance']});
        }),
      ),
    );

    final result = await repo.getOptions(
      token: 'sid',
      kind: 'types',
      searchText: 'maint',
    );
    expect(result.types, ['Maintenance']);
  });

  test('status update uses Completed and trusts native progress', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['status'], 'Completed');
          expect(body.containsKey('docstatus'), isFalse);
          return response({
            'success': true,
            'task': {
              'name': 'TASK-1',
              'subject': 'Inventory',
              'status': 'Completed',
              'progress': 100,
              'assignees': [],
              'previous_assignees': [
                {'name': 'a@example.com'},
              ],
            },
          });
        }),
      ),
    );
    final result = await repo.updateTask(
      token: 'sid',
      name: 'TASK-1',
      modified: 'v1',
      status: 'Completed',
    );
    expect(result.progress, 100);
    expect(result.assignees, isEmpty);
    expect(result.previousAssignees, hasLength(1));
  });

  test('Task options use Task API instead of ToDo permissions', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('mobile_app.api.get_task_options'));
          expect(request.url.queryParameters['kind'], 'users');
          return response({
            'users': [
              {'name': 'a@example.com', 'full_name': 'Alice'},
            ],
            'priorities': ['Low', 'Medium', 'High', 'Urgent'],
          });
        }),
      ),
    );
    final options = await repo.getOptions(token: 'sid', kind: 'users');
    expect(options.users.single.displayName, 'Alice');
    expect(options.priorities, contains('Urgent'));
  });

  test('permission refusal is never parsed as a successful Task', () async {
    final repo = TaskRepositoryImpl(
      ApiClient(
        httpClient: MockClient(
          (request) async => response({'error': 'Access denied'}),
        ),
      ),
    );
    await expectLater(
      repo.fetchTaskDetail(token: 'sid', name: 'TASK-1'),
      throwsA(isA<AccessDeniedException>()),
    );
  });
}
