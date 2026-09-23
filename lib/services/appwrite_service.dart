import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6ab383c50001b620d39f';

  static const String databaseId = '6ab386e500190cf49056';
  static const String usersTableId = '6ab38724001d34a6ff07';
  static const String concernsTableId = '6ab3893f001e85b86a85';

  static const String requirementsBucketId = '6ab397870001dad0909a';

  static final Client client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId);

  static final Account account = Account(client);
  static final TablesDB tablesDB = TablesDB(client);
  static final Realtime realtime = Realtime(client);
  static final Storage storage = Storage(client);
}
