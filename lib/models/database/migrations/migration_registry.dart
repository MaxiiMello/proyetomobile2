import 'migration.dart';
import 'migration_v1.dart';
import 'migration_v2.dart';

final List<DatabaseMigration> migrationRegistry = <DatabaseMigration>[
  MigrationV1(),
  MigrationV2(),
];
