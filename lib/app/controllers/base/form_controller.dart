import 'package:flutter/material.dart';

import 'base_controller.dart';

/// FormController offers a standard pattern for form state and validation.
abstract class FormController extends BaseController {
  final formKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form == null) return false;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}

