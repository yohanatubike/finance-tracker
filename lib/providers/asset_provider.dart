import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../database/database_helper.dart';

class AssetProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Asset> _assets = [];
  bool _isLoading = false;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  double get totalAssets {
    return _assets.fold(0.0, (sum, asset) => sum + asset.amount);
  }

  Future<void> loadAssets() async {
    _isLoading = true;
    notifyListeners();
    
    _assets = await _dbHelper.getAllAssets();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAsset(Asset asset) async {
    final id = await _dbHelper.insertAsset(asset);
    _assets.add(asset.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateAsset(Asset asset) async {
    await _dbHelper.updateAsset(asset);
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = asset;
      notifyListeners();
    }
  }

  Future<void> deleteAsset(int id) async {
    await _dbHelper.deleteAsset(id);
    _assets.removeWhere((asset) => asset.id == id);
    notifyListeners();
  }
}
