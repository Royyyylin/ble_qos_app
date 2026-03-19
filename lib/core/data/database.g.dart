// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _networkIdMeta = const VerificationMeta(
    'networkId',
  );
  @override
  late final GeneratedColumn<int> networkId = GeneratedColumn<int>(
    'network_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
    'rssi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<int> zone = GeneratedColumn<int>(
    'zone',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firmwareVerMeta = const VerificationMeta(
    'firmwareVer',
  );
  @override
  late final GeneratedColumn<String> firmwareVer = GeneratedColumn<String>(
    'firmware_ver',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capabilitiesMeta = const VerificationMeta(
    'capabilities',
  );
  @override
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
    'capabilities',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    networkId,
    groupName,
    status,
    rssi,
    zone,
    firmwareVer,
    tags,
    capabilities,
    lastSeen,
    configJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('network_id')) {
      context.handle(
        _networkIdMeta,
        networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('rssi')) {
      context.handle(
        _rssiMeta,
        rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta),
      );
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    }
    if (data.containsKey('firmware_ver')) {
      context.handle(
        _firmwareVerMeta,
        firmwareVer.isAcceptableOrUnknown(
          data['firmware_ver']!,
          _firmwareVerMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('capabilities')) {
      context.handle(
        _capabilitiesMeta,
        capabilities.isAcceptableOrUnknown(
          data['capabilities']!,
          _capabilitiesMeta,
        ),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      networkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}network_id'],
      ),
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rssi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi'],
      ),
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone'],
      ),
      firmwareVer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_ver'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      capabilities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities'],
      ),
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String? name;
  final String role;
  final int? networkId;
  final String? groupName;
  final String status;
  final int? rssi;
  final int? zone;
  final String? firmwareVer;
  final String? tags;
  final String? capabilities;
  final int lastSeen;
  final String? configJson;
  final int createdAt;
  final int updatedAt;
  const Device({
    required this.id,
    this.name,
    required this.role,
    this.networkId,
    this.groupName,
    required this.status,
    this.rssi,
    this.zone,
    this.firmwareVer,
    this.tags,
    this.capabilities,
    required this.lastSeen,
    this.configJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || networkId != null) {
      map['network_id'] = Variable<int>(networkId);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || rssi != null) {
      map['rssi'] = Variable<int>(rssi);
    }
    if (!nullToAbsent || zone != null) {
      map['zone'] = Variable<int>(zone);
    }
    if (!nullToAbsent || firmwareVer != null) {
      map['firmware_ver'] = Variable<String>(firmwareVer);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || capabilities != null) {
      map['capabilities'] = Variable<String>(capabilities);
    }
    map['last_seen'] = Variable<int>(lastSeen);
    if (!nullToAbsent || configJson != null) {
      map['config_json'] = Variable<String>(configJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      role: Value(role),
      networkId: networkId == null && nullToAbsent
          ? const Value.absent()
          : Value(networkId),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      status: Value(status),
      rssi: rssi == null && nullToAbsent ? const Value.absent() : Value(rssi),
      zone: zone == null && nullToAbsent ? const Value.absent() : Value(zone),
      firmwareVer: firmwareVer == null && nullToAbsent
          ? const Value.absent()
          : Value(firmwareVer),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      capabilities: capabilities == null && nullToAbsent
          ? const Value.absent()
          : Value(capabilities),
      lastSeen: Value(lastSeen),
      configJson: configJson == null && nullToAbsent
          ? const Value.absent()
          : Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      networkId: serializer.fromJson<int?>(json['networkId']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      status: serializer.fromJson<String>(json['status']),
      rssi: serializer.fromJson<int?>(json['rssi']),
      zone: serializer.fromJson<int?>(json['zone']),
      firmwareVer: serializer.fromJson<String?>(json['firmwareVer']),
      tags: serializer.fromJson<String?>(json['tags']),
      capabilities: serializer.fromJson<String?>(json['capabilities']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      configJson: serializer.fromJson<String?>(json['configJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'role': serializer.toJson<String>(role),
      'networkId': serializer.toJson<int?>(networkId),
      'groupName': serializer.toJson<String?>(groupName),
      'status': serializer.toJson<String>(status),
      'rssi': serializer.toJson<int?>(rssi),
      'zone': serializer.toJson<int?>(zone),
      'firmwareVer': serializer.toJson<String?>(firmwareVer),
      'tags': serializer.toJson<String?>(tags),
      'capabilities': serializer.toJson<String?>(capabilities),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'configJson': serializer.toJson<String?>(configJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Device copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    String? role,
    Value<int?> networkId = const Value.absent(),
    Value<String?> groupName = const Value.absent(),
    String? status,
    Value<int?> rssi = const Value.absent(),
    Value<int?> zone = const Value.absent(),
    Value<String?> firmwareVer = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> capabilities = const Value.absent(),
    int? lastSeen,
    Value<String?> configJson = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Device(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    role: role ?? this.role,
    networkId: networkId.present ? networkId.value : this.networkId,
    groupName: groupName.present ? groupName.value : this.groupName,
    status: status ?? this.status,
    rssi: rssi.present ? rssi.value : this.rssi,
    zone: zone.present ? zone.value : this.zone,
    firmwareVer: firmwareVer.present ? firmwareVer.value : this.firmwareVer,
    tags: tags.present ? tags.value : this.tags,
    capabilities: capabilities.present ? capabilities.value : this.capabilities,
    lastSeen: lastSeen ?? this.lastSeen,
    configJson: configJson.present ? configJson.value : this.configJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      networkId: data.networkId.present ? data.networkId.value : this.networkId,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      status: data.status.present ? data.status.value : this.status,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      zone: data.zone.present ? data.zone.value : this.zone,
      firmwareVer: data.firmwareVer.present
          ? data.firmwareVer.value
          : this.firmwareVer,
      tags: data.tags.present ? data.tags.value : this.tags,
      capabilities: data.capabilities.present
          ? data.capabilities.value
          : this.capabilities,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('networkId: $networkId, ')
          ..write('groupName: $groupName, ')
          ..write('status: $status, ')
          ..write('rssi: $rssi, ')
          ..write('zone: $zone, ')
          ..write('firmwareVer: $firmwareVer, ')
          ..write('tags: $tags, ')
          ..write('capabilities: $capabilities, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    networkId,
    groupName,
    status,
    rssi,
    zone,
    firmwareVer,
    tags,
    capabilities,
    lastSeen,
    configJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.networkId == this.networkId &&
          other.groupName == this.groupName &&
          other.status == this.status &&
          other.rssi == this.rssi &&
          other.zone == this.zone &&
          other.firmwareVer == this.firmwareVer &&
          other.tags == this.tags &&
          other.capabilities == this.capabilities &&
          other.lastSeen == this.lastSeen &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> role;
  final Value<int?> networkId;
  final Value<String?> groupName;
  final Value<String> status;
  final Value<int?> rssi;
  final Value<int?> zone;
  final Value<String?> firmwareVer;
  final Value<String?> tags;
  final Value<String?> capabilities;
  final Value<int> lastSeen;
  final Value<String?> configJson;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.networkId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.status = const Value.absent(),
    this.rssi = const Value.absent(),
    this.zone = const Value.absent(),
    this.firmwareVer = const Value.absent(),
    this.tags = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required String role,
    this.networkId = const Value.absent(),
    this.groupName = const Value.absent(),
    required String status,
    this.rssi = const Value.absent(),
    this.zone = const Value.absent(),
    this.firmwareVer = const Value.absent(),
    this.tags = const Value.absent(),
    this.capabilities = const Value.absent(),
    required int lastSeen,
    this.configJson = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role),
       status = Value(status),
       lastSeen = Value(lastSeen),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<int>? networkId,
    Expression<String>? groupName,
    Expression<String>? status,
    Expression<int>? rssi,
    Expression<int>? zone,
    Expression<String>? firmwareVer,
    Expression<String>? tags,
    Expression<String>? capabilities,
    Expression<int>? lastSeen,
    Expression<String>? configJson,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (networkId != null) 'network_id': networkId,
      if (groupName != null) 'group_name': groupName,
      if (status != null) 'status': status,
      if (rssi != null) 'rssi': rssi,
      if (zone != null) 'zone': zone,
      if (firmwareVer != null) 'firmware_ver': firmwareVer,
      if (tags != null) 'tags': tags,
      if (capabilities != null) 'capabilities': capabilities,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String>? role,
    Value<int?>? networkId,
    Value<String?>? groupName,
    Value<String>? status,
    Value<int?>? rssi,
    Value<int?>? zone,
    Value<String?>? firmwareVer,
    Value<String?>? tags,
    Value<String?>? capabilities,
    Value<int>? lastSeen,
    Value<String?>? configJson,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      networkId: networkId ?? this.networkId,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      zone: zone ?? this.zone,
      firmwareVer: firmwareVer ?? this.firmwareVer,
      tags: tags ?? this.tags,
      capabilities: capabilities ?? this.capabilities,
      lastSeen: lastSeen ?? this.lastSeen,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<int>(networkId.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (zone.present) {
      map['zone'] = Variable<int>(zone.value);
    }
    if (firmwareVer.present) {
      map['firmware_ver'] = Variable<String>(firmwareVer.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('networkId: $networkId, ')
          ..write('groupName: $groupName, ')
          ..write('status: $status, ')
          ..write('rssi: $rssi, ')
          ..write('zone: $zone, ')
          ..write('firmwareVer: $firmwareVer, ')
          ..write('tags: $tags, ')
          ..write('capabilities: $capabilities, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawPayloadMeta = const VerificationMeta(
    'rawPayload',
  );
  @override
  late final GeneratedColumn<Uint8List> rawPayload = GeneratedColumn<Uint8List>(
    'raw_payload',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    severity,
    type,
    message,
    rawPayload,
    acknowledged,
    createdAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('raw_payload')) {
      context.handle(
        _rawPayloadMeta,
        rawPayload.isAcceptableOrUnknown(data['raw_payload']!, _rawPayloadMeta),
      );
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      rawPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}raw_payload'],
      ),
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final int id;
  final String? deviceId;
  final String severity;
  final String type;
  final String? message;
  final Uint8List? rawPayload;
  final bool acknowledged;
  final int createdAt;
  final int? resolvedAt;
  const Alert({
    required this.id,
    this.deviceId,
    required this.severity,
    required this.type,
    this.message,
    this.rawPayload,
    required this.acknowledged,
    required this.createdAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['severity'] = Variable<String>(severity);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || rawPayload != null) {
      map['raw_payload'] = Variable<Uint8List>(rawPayload);
    }
    map['acknowledged'] = Variable<bool>(acknowledged);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      severity: Value(severity),
      type: Value(type),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      rawPayload: rawPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPayload),
      acknowledged: Value(acknowledged),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory Alert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      severity: serializer.fromJson<String>(json['severity']),
      type: serializer.fromJson<String>(json['type']),
      message: serializer.fromJson<String?>(json['message']),
      rawPayload: serializer.fromJson<Uint8List?>(json['rawPayload']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      resolvedAt: serializer.fromJson<int?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String?>(deviceId),
      'severity': serializer.toJson<String>(severity),
      'type': serializer.toJson<String>(type),
      'message': serializer.toJson<String?>(message),
      'rawPayload': serializer.toJson<Uint8List?>(rawPayload),
      'acknowledged': serializer.toJson<bool>(acknowledged),
      'createdAt': serializer.toJson<int>(createdAt),
      'resolvedAt': serializer.toJson<int?>(resolvedAt),
    };
  }

  Alert copyWith({
    int? id,
    Value<String?> deviceId = const Value.absent(),
    String? severity,
    String? type,
    Value<String?> message = const Value.absent(),
    Value<Uint8List?> rawPayload = const Value.absent(),
    bool? acknowledged,
    int? createdAt,
    Value<int?> resolvedAt = const Value.absent(),
  }) => Alert(
    id: id ?? this.id,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    severity: severity ?? this.severity,
    type: type ?? this.type,
    message: message.present ? message.value : this.message,
    rawPayload: rawPayload.present ? rawPayload.value : this.rawPayload,
    acknowledged: acknowledged ?? this.acknowledged,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  Alert copyWithCompanion(AlertsCompanion data) {
    return Alert(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      severity: data.severity.present ? data.severity.value : this.severity,
      type: data.type.present ? data.type.value : this.type,
      message: data.message.present ? data.message.value : this.message,
      rawPayload: data.rawPayload.present
          ? data.rawPayload.value
          : this.rawPayload,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('severity: $severity, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    severity,
    type,
    message,
    $driftBlobEquality.hash(rawPayload),
    acknowledged,
    createdAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.severity == this.severity &&
          other.type == this.type &&
          other.message == this.message &&
          $driftBlobEquality.equals(other.rawPayload, this.rawPayload) &&
          other.acknowledged == this.acknowledged &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<int> id;
  final Value<String?> deviceId;
  final Value<String> severity;
  final Value<String> type;
  final Value<String?> message;
  final Value<Uint8List?> rawPayload;
  final Value<bool> acknowledged;
  final Value<int> createdAt;
  final Value<int?> resolvedAt;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.severity = const Value.absent(),
    this.type = const Value.absent(),
    this.message = const Value.absent(),
    this.rawPayload = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  AlertsCompanion.insert({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    required String severity,
    required String type,
    this.message = const Value.absent(),
    this.rawPayload = const Value.absent(),
    this.acknowledged = const Value.absent(),
    required int createdAt,
    this.resolvedAt = const Value.absent(),
  }) : severity = Value(severity),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<Alert> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? severity,
    Expression<String>? type,
    Expression<String>? message,
    Expression<Uint8List>? rawPayload,
    Expression<bool>? acknowledged,
    Expression<int>? createdAt,
    Expression<int>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (severity != null) 'severity': severity,
      if (type != null) 'type': type,
      if (message != null) 'message': message,
      if (rawPayload != null) 'raw_payload': rawPayload,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  AlertsCompanion copyWith({
    Value<int>? id,
    Value<String?>? deviceId,
    Value<String>? severity,
    Value<String>? type,
    Value<String?>? message,
    Value<Uint8List?>? rawPayload,
    Value<bool>? acknowledged,
    Value<int>? createdAt,
    Value<int?>? resolvedAt,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      message: message ?? this.message,
      rawPayload: rawPayload ?? this.rawPayload,
      acknowledged: acknowledged ?? this.acknowledged,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (rawPayload.present) {
      map['raw_payload'] = Variable<Uint8List>(rawPayload.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('severity: $severity, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userRoleMeta = const VerificationMeta(
    'userRole',
  );
  @override
  late final GeneratedColumn<String> userRole = GeneratedColumn<String>(
    'user_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDeviceMeta = const VerificationMeta(
    'targetDevice',
  );
  @override
  late final GeneratedColumn<String> targetDevice = GeneratedColumn<String>(
    'target_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailBeforeMeta = const VerificationMeta(
    'detailBefore',
  );
  @override
  late final GeneratedColumn<String> detailBefore = GeneratedColumn<String>(
    'detail_before',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailAfterMeta = const VerificationMeta(
    'detailAfter',
  );
  @override
  late final GeneratedColumn<String> detailAfter = GeneratedColumn<String>(
    'detail_after',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userRole,
    action,
    targetDevice,
    detailBefore,
    detailAfter,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_role')) {
      context.handle(
        _userRoleMeta,
        userRole.isAcceptableOrUnknown(data['user_role']!, _userRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_userRoleMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('target_device')) {
      context.handle(
        _targetDeviceMeta,
        targetDevice.isAcceptableOrUnknown(
          data['target_device']!,
          _targetDeviceMeta,
        ),
      );
    }
    if (data.containsKey('detail_before')) {
      context.handle(
        _detailBeforeMeta,
        detailBefore.isAcceptableOrUnknown(
          data['detail_before']!,
          _detailBeforeMeta,
        ),
      );
    }
    if (data.containsKey('detail_after')) {
      context.handle(
        _detailAfterMeta,
        detailAfter.isAcceptableOrUnknown(
          data['detail_after']!,
          _detailAfterMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_role'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      targetDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_device'],
      ),
      detailBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_before'],
      ),
      detailAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_after'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final String userRole;
  final String action;
  final String? targetDevice;
  final String? detailBefore;
  final String? detailAfter;
  final int createdAt;
  const AuditLogData({
    required this.id,
    required this.userRole,
    required this.action,
    this.targetDevice,
    this.detailBefore,
    this.detailAfter,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_role'] = Variable<String>(userRole);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || targetDevice != null) {
      map['target_device'] = Variable<String>(targetDevice);
    }
    if (!nullToAbsent || detailBefore != null) {
      map['detail_before'] = Variable<String>(detailBefore);
    }
    if (!nullToAbsent || detailAfter != null) {
      map['detail_after'] = Variable<String>(detailAfter);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      userRole: Value(userRole),
      action: Value(action),
      targetDevice: targetDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDevice),
      detailBefore: detailBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(detailBefore),
      detailAfter: detailAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(detailAfter),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      userRole: serializer.fromJson<String>(json['userRole']),
      action: serializer.fromJson<String>(json['action']),
      targetDevice: serializer.fromJson<String?>(json['targetDevice']),
      detailBefore: serializer.fromJson<String?>(json['detailBefore']),
      detailAfter: serializer.fromJson<String?>(json['detailAfter']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userRole': serializer.toJson<String>(userRole),
      'action': serializer.toJson<String>(action),
      'targetDevice': serializer.toJson<String?>(targetDevice),
      'detailBefore': serializer.toJson<String?>(detailBefore),
      'detailAfter': serializer.toJson<String?>(detailAfter),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AuditLogData copyWith({
    int? id,
    String? userRole,
    String? action,
    Value<String?> targetDevice = const Value.absent(),
    Value<String?> detailBefore = const Value.absent(),
    Value<String?> detailAfter = const Value.absent(),
    int? createdAt,
  }) => AuditLogData(
    id: id ?? this.id,
    userRole: userRole ?? this.userRole,
    action: action ?? this.action,
    targetDevice: targetDevice.present ? targetDevice.value : this.targetDevice,
    detailBefore: detailBefore.present ? detailBefore.value : this.detailBefore,
    detailAfter: detailAfter.present ? detailAfter.value : this.detailAfter,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      userRole: data.userRole.present ? data.userRole.value : this.userRole,
      action: data.action.present ? data.action.value : this.action,
      targetDevice: data.targetDevice.present
          ? data.targetDevice.value
          : this.targetDevice,
      detailBefore: data.detailBefore.present
          ? data.detailBefore.value
          : this.detailBefore,
      detailAfter: data.detailAfter.present
          ? data.detailAfter.value
          : this.detailAfter,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('userRole: $userRole, ')
          ..write('action: $action, ')
          ..write('targetDevice: $targetDevice, ')
          ..write('detailBefore: $detailBefore, ')
          ..write('detailAfter: $detailAfter, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userRole,
    action,
    targetDevice,
    detailBefore,
    detailAfter,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.userRole == this.userRole &&
          other.action == this.action &&
          other.targetDevice == this.targetDevice &&
          other.detailBefore == this.detailBefore &&
          other.detailAfter == this.detailAfter &&
          other.createdAt == this.createdAt);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<String> userRole;
  final Value<String> action;
  final Value<String?> targetDevice;
  final Value<String?> detailBefore;
  final Value<String?> detailAfter;
  final Value<int> createdAt;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.userRole = const Value.absent(),
    this.action = const Value.absent(),
    this.targetDevice = const Value.absent(),
    this.detailBefore = const Value.absent(),
    this.detailAfter = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String userRole,
    required String action,
    this.targetDevice = const Value.absent(),
    this.detailBefore = const Value.absent(),
    this.detailAfter = const Value.absent(),
    required int createdAt,
  }) : userRole = Value(userRole),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<String>? userRole,
    Expression<String>? action,
    Expression<String>? targetDevice,
    Expression<String>? detailBefore,
    Expression<String>? detailAfter,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userRole != null) 'user_role': userRole,
      if (action != null) 'action': action,
      if (targetDevice != null) 'target_device': targetDevice,
      if (detailBefore != null) 'detail_before': detailBefore,
      if (detailAfter != null) 'detail_after': detailAfter,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AuditLogCompanion copyWith({
    Value<int>? id,
    Value<String>? userRole,
    Value<String>? action,
    Value<String?>? targetDevice,
    Value<String?>? detailBefore,
    Value<String?>? detailAfter,
    Value<int>? createdAt,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      targetDevice: targetDevice ?? this.targetDevice,
      detailBefore: detailBefore ?? this.detailBefore,
      detailAfter: detailAfter ?? this.detailAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userRole.present) {
      map['user_role'] = Variable<String>(userRole.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (targetDevice.present) {
      map['target_device'] = Variable<String>(targetDevice.value);
    }
    if (detailBefore.present) {
      map['detail_before'] = Variable<String>(detailBefore.value);
    }
    if (detailAfter.present) {
      map['detail_after'] = Variable<String>(detailAfter.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('userRole: $userRole, ')
          ..write('action: $action, ')
          ..write('targetDevice: $targetDevice, ')
          ..write('detailBefore: $detailBefore, ')
          ..write('detailAfter: $detailAfter, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DeviceTelemetryTable extends DeviceTelemetry
    with TableInfo<$DeviceTelemetryTable, DeviceTelemetryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTelemetryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
    'rssi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<int> zone = GeneratedColumn<int>(
    'zone',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensorDataMeta = const VerificationMeta(
    'sensorData',
  );
  @override
  late final GeneratedColumn<String> sensorData = GeneratedColumn<String>(
    'sensor_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    timestamp,
    rssi,
    zone,
    sensorData,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_telemetry';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceTelemetryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rssi')) {
      context.handle(
        _rssiMeta,
        rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta),
      );
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    }
    if (data.containsKey('sensor_data')) {
      context.handle(
        _sensorDataMeta,
        sensorData.isAcceptableOrUnknown(data['sensor_data']!, _sensorDataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {deviceId, timestamp},
  ];
  @override
  DeviceTelemetryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceTelemetryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      rssi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi'],
      ),
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone'],
      ),
      sensorData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensor_data'],
      ),
    );
  }

  @override
  $DeviceTelemetryTable createAlias(String alias) {
    return $DeviceTelemetryTable(attachedDatabase, alias);
  }
}

class DeviceTelemetryData extends DataClass
    implements Insertable<DeviceTelemetryData> {
  final int id;
  final String deviceId;
  final int timestamp;
  final int? rssi;
  final int? zone;
  final String? sensorData;
  const DeviceTelemetryData({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    this.rssi,
    this.zone,
    this.sensorData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || rssi != null) {
      map['rssi'] = Variable<int>(rssi);
    }
    if (!nullToAbsent || zone != null) {
      map['zone'] = Variable<int>(zone);
    }
    if (!nullToAbsent || sensorData != null) {
      map['sensor_data'] = Variable<String>(sensorData);
    }
    return map;
  }

  DeviceTelemetryCompanion toCompanion(bool nullToAbsent) {
    return DeviceTelemetryCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      timestamp: Value(timestamp),
      rssi: rssi == null && nullToAbsent ? const Value.absent() : Value(rssi),
      zone: zone == null && nullToAbsent ? const Value.absent() : Value(zone),
      sensorData: sensorData == null && nullToAbsent
          ? const Value.absent()
          : Value(sensorData),
    );
  }

  factory DeviceTelemetryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceTelemetryData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      rssi: serializer.fromJson<int?>(json['rssi']),
      zone: serializer.fromJson<int?>(json['zone']),
      sensorData: serializer.fromJson<String?>(json['sensorData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'timestamp': serializer.toJson<int>(timestamp),
      'rssi': serializer.toJson<int?>(rssi),
      'zone': serializer.toJson<int?>(zone),
      'sensorData': serializer.toJson<String?>(sensorData),
    };
  }

  DeviceTelemetryData copyWith({
    int? id,
    String? deviceId,
    int? timestamp,
    Value<int?> rssi = const Value.absent(),
    Value<int?> zone = const Value.absent(),
    Value<String?> sensorData = const Value.absent(),
  }) => DeviceTelemetryData(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    timestamp: timestamp ?? this.timestamp,
    rssi: rssi.present ? rssi.value : this.rssi,
    zone: zone.present ? zone.value : this.zone,
    sensorData: sensorData.present ? sensorData.value : this.sensorData,
  );
  DeviceTelemetryData copyWithCompanion(DeviceTelemetryCompanion data) {
    return DeviceTelemetryData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      zone: data.zone.present ? data.zone.value : this.zone,
      sensorData: data.sensorData.present
          ? data.sensorData.value
          : this.sensorData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTelemetryData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rssi: $rssi, ')
          ..write('zone: $zone, ')
          ..write('sensorData: $sensorData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deviceId, timestamp, rssi, zone, sensorData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceTelemetryData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.timestamp == this.timestamp &&
          other.rssi == this.rssi &&
          other.zone == this.zone &&
          other.sensorData == this.sensorData);
}

class DeviceTelemetryCompanion extends UpdateCompanion<DeviceTelemetryData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<int> timestamp;
  final Value<int?> rssi;
  final Value<int?> zone;
  final Value<String?> sensorData;
  const DeviceTelemetryCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rssi = const Value.absent(),
    this.zone = const Value.absent(),
    this.sensorData = const Value.absent(),
  });
  DeviceTelemetryCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required int timestamp,
    this.rssi = const Value.absent(),
    this.zone = const Value.absent(),
    this.sensorData = const Value.absent(),
  }) : deviceId = Value(deviceId),
       timestamp = Value(timestamp);
  static Insertable<DeviceTelemetryData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<int>? timestamp,
    Expression<int>? rssi,
    Expression<int>? zone,
    Expression<String>? sensorData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rssi != null) 'rssi': rssi,
      if (zone != null) 'zone': zone,
      if (sensorData != null) 'sensor_data': sensorData,
    });
  }

  DeviceTelemetryCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<int>? timestamp,
    Value<int?>? rssi,
    Value<int?>? zone,
    Value<String?>? sensorData,
  }) {
    return DeviceTelemetryCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      rssi: rssi ?? this.rssi,
      zone: zone ?? this.zone,
      sensorData: sensorData ?? this.sensorData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (zone.present) {
      map['zone'] = Variable<int>(zone.value);
    }
    if (sensorData.present) {
      map['sensor_data'] = Variable<String>(sensorData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTelemetryCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rssi: $rssi, ')
          ..write('zone: $zone, ')
          ..write('sensorData: $sensorData')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DeviceTelemetryTable deviceTelemetry = $DeviceTelemetryTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    devices,
    alerts,
    auditLog,
    deviceTelemetry,
  ];
}

typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String id,
      Value<String?> name,
      required String role,
      Value<int?> networkId,
      Value<String?> groupName,
      required String status,
      Value<int?> rssi,
      Value<int?> zone,
      Value<String?> firmwareVer,
      Value<String?> tags,
      Value<String?> capabilities,
      required int lastSeen,
      Value<String?> configJson,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String> role,
      Value<int?> networkId,
      Value<String?> groupName,
      Value<String> status,
      Value<int?> rssi,
      Value<int?> zone,
      Value<String?> firmwareVer,
      Value<String?> tags,
      Value<String?> capabilities,
      Value<int> lastSeen,
      Value<String?> configJson,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get networkId => $composableBuilder(
    column: $table.networkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmwareVer => $composableBuilder(
    column: $table.firmwareVer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get networkId => $composableBuilder(
    column: $table.networkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmwareVer => $composableBuilder(
    column: $table.firmwareVer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get networkId =>
      $composableBuilder(column: $table.networkId, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<int> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumn<String> get firmwareVer => $composableBuilder(
    column: $table.firmwareVer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int?> networkId = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<int?> zone = const Value.absent(),
                Value<String?> firmwareVer = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> capabilities = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
                Value<String?> configJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                name: name,
                role: role,
                networkId: networkId,
                groupName: groupName,
                status: status,
                rssi: rssi,
                zone: zone,
                firmwareVer: firmwareVer,
                tags: tags,
                capabilities: capabilities,
                lastSeen: lastSeen,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                required String role,
                Value<int?> networkId = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                required String status,
                Value<int?> rssi = const Value.absent(),
                Value<int?> zone = const Value.absent(),
                Value<String?> firmwareVer = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> capabilities = const Value.absent(),
                required int lastSeen,
                Value<String?> configJson = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                name: name,
                role: role,
                networkId: networkId,
                groupName: groupName,
                status: status,
                rssi: rssi,
                zone: zone,
                firmwareVer: firmwareVer,
                tags: tags,
                capabilities: capabilities,
                lastSeen: lastSeen,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
      Device,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableCreateCompanionBuilder =
    AlertsCompanion Function({
      Value<int> id,
      Value<String?> deviceId,
      required String severity,
      required String type,
      Value<String?> message,
      Value<Uint8List?> rawPayload,
      Value<bool> acknowledged,
      required int createdAt,
      Value<int?> resolvedAt,
    });
typedef $$AlertsTableUpdateCompanionBuilder =
    AlertsCompanion Function({
      Value<int> id,
      Value<String?> deviceId,
      Value<String> severity,
      Value<String> type,
      Value<String?> message,
      Value<Uint8List?> rawPayload,
      Value<bool> acknowledged,
      Value<int> createdAt,
      Value<int?> resolvedAt,
    });

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<Uint8List> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          Alert,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
          Alert,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<Uint8List?> rawPayload = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> resolvedAt = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                deviceId: deviceId,
                severity: severity,
                type: type,
                message: message,
                rawPayload: rawPayload,
                acknowledged: acknowledged,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                required String severity,
                required String type,
                Value<String?> message = const Value.absent(),
                Value<Uint8List?> rawPayload = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                required int createdAt,
                Value<int?> resolvedAt = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                deviceId: deviceId,
                severity: severity,
                type: type,
                message: message,
                rawPayload: rawPayload,
                acknowledged: acknowledged,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      Alert,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
      Alert,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder =
    AuditLogCompanion Function({
      Value<int> id,
      required String userRole,
      required String action,
      Value<String?> targetDevice,
      Value<String?> detailBefore,
      Value<String?> detailAfter,
      required int createdAt,
    });
typedef $$AuditLogTableUpdateCompanionBuilder =
    AuditLogCompanion Function({
      Value<int> id,
      Value<String> userRole,
      Value<String> action,
      Value<String?> targetDevice,
      Value<String?> detailBefore,
      Value<String?> detailAfter,
      Value<int> createdAt,
    });

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userRole => $composableBuilder(
    column: $table.userRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDevice => $composableBuilder(
    column: $table.targetDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailBefore => $composableBuilder(
    column: $table.detailBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailAfter => $composableBuilder(
    column: $table.detailAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userRole => $composableBuilder(
    column: $table.userRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDevice => $composableBuilder(
    column: $table.targetDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailBefore => $composableBuilder(
    column: $table.detailBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailAfter => $composableBuilder(
    column: $table.detailAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userRole =>
      $composableBuilder(column: $table.userRole, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get targetDevice => $composableBuilder(
    column: $table.targetDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailBefore => $composableBuilder(
    column: $table.detailBefore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailAfter => $composableBuilder(
    column: $table.detailAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditLogData,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogData,
            BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>,
          ),
          AuditLogData,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userRole = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> targetDevice = const Value.absent(),
                Value<String?> detailBefore = const Value.absent(),
                Value<String?> detailAfter = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                userRole: userRole,
                action: action,
                targetDevice: targetDevice,
                detailBefore: detailBefore,
                detailAfter: detailAfter,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userRole,
                required String action,
                Value<String?> targetDevice = const Value.absent(),
                Value<String?> detailBefore = const Value.absent(),
                Value<String?> detailAfter = const Value.absent(),
                required int createdAt,
              }) => AuditLogCompanion.insert(
                id: id,
                userRole: userRole,
                action: action,
                targetDevice: targetDevice,
                detailBefore: detailBefore,
                detailAfter: detailAfter,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditLogData,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (
        AuditLogData,
        BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>,
      ),
      AuditLogData,
      PrefetchHooks Function()
    >;
typedef $$DeviceTelemetryTableCreateCompanionBuilder =
    DeviceTelemetryCompanion Function({
      Value<int> id,
      required String deviceId,
      required int timestamp,
      Value<int?> rssi,
      Value<int?> zone,
      Value<String?> sensorData,
    });
typedef $$DeviceTelemetryTableUpdateCompanionBuilder =
    DeviceTelemetryCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<int> timestamp,
      Value<int?> rssi,
      Value<int?> zone,
      Value<String?> sensorData,
    });

class $$DeviceTelemetryTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceTelemetryTable> {
  $$DeviceTelemetryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensorData => $composableBuilder(
    column: $table.sensorData,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceTelemetryTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceTelemetryTable> {
  $$DeviceTelemetryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensorData => $composableBuilder(
    column: $table.sensorData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceTelemetryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceTelemetryTable> {
  $$DeviceTelemetryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<int> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumn<String> get sensorData => $composableBuilder(
    column: $table.sensorData,
    builder: (column) => column,
  );
}

class $$DeviceTelemetryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceTelemetryTable,
          DeviceTelemetryData,
          $$DeviceTelemetryTableFilterComposer,
          $$DeviceTelemetryTableOrderingComposer,
          $$DeviceTelemetryTableAnnotationComposer,
          $$DeviceTelemetryTableCreateCompanionBuilder,
          $$DeviceTelemetryTableUpdateCompanionBuilder,
          (
            DeviceTelemetryData,
            BaseReferences<
              _$AppDatabase,
              $DeviceTelemetryTable,
              DeviceTelemetryData
            >,
          ),
          DeviceTelemetryData,
          PrefetchHooks Function()
        > {
  $$DeviceTelemetryTableTableManager(
    _$AppDatabase db,
    $DeviceTelemetryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTelemetryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTelemetryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTelemetryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<int?> zone = const Value.absent(),
                Value<String?> sensorData = const Value.absent(),
              }) => DeviceTelemetryCompanion(
                id: id,
                deviceId: deviceId,
                timestamp: timestamp,
                rssi: rssi,
                zone: zone,
                sensorData: sensorData,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                required int timestamp,
                Value<int?> rssi = const Value.absent(),
                Value<int?> zone = const Value.absent(),
                Value<String?> sensorData = const Value.absent(),
              }) => DeviceTelemetryCompanion.insert(
                id: id,
                deviceId: deviceId,
                timestamp: timestamp,
                rssi: rssi,
                zone: zone,
                sensorData: sensorData,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceTelemetryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceTelemetryTable,
      DeviceTelemetryData,
      $$DeviceTelemetryTableFilterComposer,
      $$DeviceTelemetryTableOrderingComposer,
      $$DeviceTelemetryTableAnnotationComposer,
      $$DeviceTelemetryTableCreateCompanionBuilder,
      $$DeviceTelemetryTableUpdateCompanionBuilder,
      (
        DeviceTelemetryData,
        BaseReferences<
          _$AppDatabase,
          $DeviceTelemetryTable,
          DeviceTelemetryData
        >,
      ),
      DeviceTelemetryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$DeviceTelemetryTableTableManager get deviceTelemetry =>
      $$DeviceTelemetryTableTableManager(_db, _db.deviceTelemetry);
}
