import 'dart:math';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:poke_match/core/state/id_list_provider.dart';
import 'package:poke_match/core/state/matched_pokemon_provider.dart';
import 'package:poke_match/data/repositories/pokemon_repository.dart';
import 'package:poke_match/domain/models/pokemon.dart';
import 'package:poke_match/presentations/views/widgets/dialog_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_view_model.g.dart';

@Riverpod(keepAlive: true)
class HomePageViewModel extends _$HomePageViewModel {
  @override
  Future<List<Pokemon>> build() async {
    final pokemonRepository = ref.watch(pokemonRepositoryProvider);
    final idListState = ref.read(idListProvider);
    final idListNotifier = ref.read(idListProvider.notifier);

    List<Pokemon> list = [];
    for (int i = 0; i < 5; i++) {
      final pokemon =
          await pokemonRepository.getPokemonById(idListState[i].toString());
      list.add(pokemon);
      idListNotifier.remove();
    }

    // ランダムな数字のリストを作成
    myIdList = _generateRandomNumbers(200, 1, 1000);

    return list;
  }

  final swipeController = AppinioSwiperController();

  /// idのリスト
  /// * Likeした際にこれに{pokemon.id}が含まれていればマッチ判定
  List<int> myIdList = [];

  /// スワイプした回数
  /// * view側: AppinioSwiperのinitialIndex
  /// * [caution] 画面遷移した際にAppinioSwiperのindexがリセットされるため
  int swipeCount = 0;

  /// スワイプ時の処理
  Future<void> onSwipeEnd(
    BuildContext context,
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) async {
    if (activity is Swipe) {
      // スワイプ中のポケモン
      final pokemon = state.value![previousIndex];

      debugPrint('Swiped ${state.value![previousIndex]}');

      switch (activity.direction) {
        case AxisDirection.left:
          _swipeLeft(context, pokemon);
          break;
        case AxisDirection.right:
          _swipeRight(context, pokemon);
          break;
        case AxisDirection.up:
          _swipeUp(context, pokemon);
          break;
        case AxisDirection.down:
          _swipeDown(context, pokemon);
          break;
        default:
          break;
      }
    }
  }

  /// 左にスワイプしたときの処理
  Future<void> _swipeLeft(BuildContext context, Pokemon pokemon) async {
    debugPrint('Swiped Left');
    await _updatePokemonList();
  }

  /// 右にスワイプしたときの処理
  Future<void> _swipeRight(BuildContext context, Pokemon pokemon) async {
    debugPrint('Swiped Right');
    final isMatch = myIdList.contains(pokemon.id);
    await _updatePokemonList();
    if (isMatch) {
      await _showMatchDialog(context, pokemon.imageUrl);
      ref
          .read(matchedPokemonProviderProvider.notifier)
          .addMatchedPokemon(pokemon);
    }
  }

  /// 上にスワイプしたときの処理
  Future<void> _swipeUp(BuildContext context, Pokemon pokemon) async {
    debugPrint('Swiped Up');
    await _updatePokemonList();
    await _showMatchDialog(context, pokemon.imageUrl);
    ref
        .read(matchedPokemonProviderProvider.notifier)
        .addMatchedPokemon(pokemon);
  }

  /// 左にスワイプしたときの処理
  Future<void> _swipeDown(BuildContext context, Pokemon pokemon) async {
    debugPrint('Swiped Left');
    await _updatePokemonList();
  }

  /// マッチした場合にダイアログを表示
  Future<void> _showMatchDialog(BuildContext context, String imageUrl) async {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return DialogContent(imageUrl: imageUrl);
      },
    );
  }

  /// 新たにポケモンを取得しstateを更新
  Future<void> _updatePokemonList() async {
    final pokemonRepository = ref.watch(pokemonRepositoryProvider);
    final idListState = ref.read(idListProvider);
    final idListNotifier = ref.read(idListProvider.notifier);

    final newPokemonList = List<Pokemon>.from(state.value!);

    swipeCount++;

    final pokemon =
        await pokemonRepository.getPokemonById(idListState[0].toString());

    newPokemonList.add(pokemon);

    idListNotifier.remove();
    state = AsyncValue.data(newPokemonList);
  }

  /// minからmaxまでの範囲でランダムな数字のListを作成する(count: 要素数)
  List<int> _generateRandomNumbers(int count, int min, int max) {
    Random random = Random();
    List<int> numbers = [];

    for (int i = 0; i < count; i++) {
      int randomNumber = min + random.nextInt(max - min + 1);
      numbers.add(randomNumber);
    }

    return numbers;
  }
}
