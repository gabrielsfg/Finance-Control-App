import 'package:flutter/material.dart';

enum WishlistPriority { low, medium, high }

extension WishlistPriorityExtension on WishlistPriority {
  static WishlistPriority fromInt(int value) {
    switch (value) {
      case 0:
        return WishlistPriority.low;
      case 1:
        return WishlistPriority.medium;
      case 2:
        return WishlistPriority.high;
      default:
        return WishlistPriority.low;
    }
  }

  int toInt() {
    switch (this) {
      case WishlistPriority.low:
        return 0;
      case WishlistPriority.medium:
        return 1;
      case WishlistPriority.high:
        return 2;
    }
  }

  String get label {
    switch (this) {
      case WishlistPriority.low:
        return 'Baixa';
      case WishlistPriority.medium:
        return 'Média';
      case WishlistPriority.high:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case WishlistPriority.low:
        return Colors.grey;
      case WishlistPriority.medium:
        return Colors.orange;
      case WishlistPriority.high:
        return Colors.red;
    }
  }
}

enum WishlistStatus { active, purchased, archived }

extension WishlistStatusExtension on WishlistStatus {
  static WishlistStatus fromInt(int value) {
    switch (value) {
      case 0:
        return WishlistStatus.active;
      case 1:
        return WishlistStatus.purchased;
      case 2:
        return WishlistStatus.archived;
      default:
        return WishlistStatus.active;
    }
  }

  int toInt() {
    switch (this) {
      case WishlistStatus.active:
        return 0;
      case WishlistStatus.purchased:
        return 1;
      case WishlistStatus.archived:
        return 2;
    }
  }

  String get label {
    switch (this) {
      case WishlistStatus.active:
        return 'Ativo';
      case WishlistStatus.purchased:
        return 'Comprado';
      case WishlistStatus.archived:
        return 'Arquivado';
    }
  }
}
