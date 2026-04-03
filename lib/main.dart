import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive本地存储
  await Hive.initFlutter();

  // 初始化Supabase
  await Supabase.initialize(
    url: 'https://fmeiawlltymosqhusmwb.supabase.co',
    anonKey: 'sb_publishable_BjxLUla5ZQUKJF7AIgQGRA_XvpxIB5C',
  );

  runApp(
    const ProviderScope(
      child: DianPiaoApp(),
    ),
  );
}
