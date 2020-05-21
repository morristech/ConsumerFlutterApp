import 'package:LaCoro/core/appearance/app_colors.dart';
import 'package:LaCoro/core/appearance/app_text_style.dart';
import 'package:LaCoro/core/bloc/base_bloc.dart';
import 'package:LaCoro/core/localization/app_localizations.dart';
import 'package:LaCoro/core/ui_utils/custom_widgets/store_item.dart';
import 'package:LaCoro/core/ui_utils/model/store_ui.dart';
import 'package:LaCoro/presentation/adresses/my_address_page.dart';
import 'package:LaCoro/presentation/store_details/store_details_page.dart';
import 'package:LaCoro/presentation/store_list/store_list_bloc.dart';
import 'package:domain/use_cases/store_use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class StoreListPage extends StatefulWidget {
  static const STORE_LIST_ROUTE = '/store_list';

  @override
  _StoreListPageState createState() =>
      _StoreListPageState((Injector.getInjector().get()));
}

class _StoreListPageState extends State<StoreListPage> {
  final RefreshController _refreshController = RefreshController();
  final StoreListBloc _bloc;
  FocusNode _focusNode;
  TextEditingController _textFieldController;

  _StoreListPageState(this._bloc);

  List<StoreUI> _stores;
  bool _loading = false;
  String searchQuery;

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      //TODO no funciona el desenfoque del textLabel al regresar a la lista
    });
    super.initState();
    _bloc.add(GetStoresEvent(searchQuery: searchQuery));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final currentAddress = _bloc.loadSavedAddress();
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
            elevation: 0,
            title: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, MyAddressPage.MY_ADDRESS_ROUTE),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                      '${currentAddress.address}, ${currentAddress.cityEntity.name}',
                      style:
                          AppTextStyle.section.copyWith(color: Colors.black)),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 36,
                    color: Theme.of(context).accentColor,
                  )
                ],
              ),
            )),
        body: BlocListener(
            bloc: _bloc,
            listener: (context, state) {
              setState(() => _loading = false);
              _refreshController.refreshCompleted();

              if (state is LoadingState) setState(() => _loading = true);

              if (state is SuccessState<List<StoreUI>>)
                setState(() => _stores = state.data);

              if (state is MoreStoresLoadedState)
                setState(() => _stores.addAll(state.data));

              //if (state is ErrorState)// TODO show error banner
            },
            child: Stack(children: [
              Column(
                children: <Widget>[
                  Padding(
                    // todo sacar en un widget
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      borderRadius: BorderRadius.all(Radius.circular(6.0)),
                      shadowColor: AppColors.greyMedium,
                      elevation: 2,
                      color: Colors.white,
                      child: TextField(
                          focusNode: _focusNode,
                          controller: _textFieldController,
                          decoration: InputDecoration(
                            filled: true, //fillColor: Colors.red,
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.greyMedium, size: 24),
                            suffixIcon: Icon(Icons.cancel,
                                color: Colors.black, size: 24),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).accentColor,
                              ),
                            ),

                            hintText: strings.searchYourAddress,
                            hintStyle: AppTextStyle.grey16,
//                            border: OutlineInputBorder(),
//                              focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                          keyboardType: TextInputType.text),
                    ),
                  ),
                  Expanded(
                    child: LazyLoadScrollView(
                      onEndOfPage: () {
                        if (_stores != null &&
                            _stores.length >= StoreUseCases.PAGE_SIZE)
                          _bloc.add(
                              LoadMoreStoresEvent(searchQuery: searchQuery));
                      },
                      child: SmartRefresher(
                        controller: _refreshController,
                        enablePullDown: true,
                        onRefresh: () =>
                            _bloc.add(GetStoresEvent(searchQuery: searchQuery)),
                        child: buildList(),
                      ),
                    ),
                  ),
                ],
              ),
              Center(child: _loading ? CircularProgressIndicator() : null),
            ])));
  }

  Widget buildList() {
    return ListView.separated(
        separatorBuilder: (c, i) => SizedBox(height: 24.0),
        itemBuilder: (c, index) {
          return InkWell(
              onTap: () {
                if (_focusNode.hasFocus) _textFieldController.clear();
                return Navigator.pushNamed(
                    context, StoreDetailsPage.STORE_DETAILS_ROUTE,
                    arguments: _stores[index]);
              },
              child: Hero(
                  tag: _stores[index].name,
                  child: StoreItem(storeItem: _stores[index])));
        },
        itemCount: _stores?.length ?? 0);
  }
}
