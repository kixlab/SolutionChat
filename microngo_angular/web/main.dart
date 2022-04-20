// Copyright (c) 2017, S.-C. Lee. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'package:angular/angular.dart';
import 'package:http/browser_client.dart';

import 'main.template.dart' as self;
import 'package:microngo_angular/app_component.template.dart' as ng;

@GenerateInjector([
  const ClassProvider(BrowserClient),
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}