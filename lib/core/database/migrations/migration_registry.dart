import 'migration.dart';
import 'migration_v1.dart';

final List<DatabaseMigration> migrationRegistry = <DatabaseMigration>[
  MigrationV1(),
];
