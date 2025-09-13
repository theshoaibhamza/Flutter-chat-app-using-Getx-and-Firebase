import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';

import 'package:internee_app3/app/Widgets/my_text.dart';

import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchController> {
  const SearchView({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //MyContainer(height: 20, width: 120, child: MyText(text: "text")),
          SearchBar(
            onSubmitted: (value) {},
            onChanged: (value) {
              controller.debouncer.run(() {
                print("I am called after 1000 mili seconds");
                controller.search();
              });
            },
            hintText: "Search",
            leading: Icon(Icons.search),
            controller: controller.searchController.value,
          ),

          SizedBox(height: 10),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  {
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(controller.users[index]['email']),
                            Spacer(),

                            ElevatedButton(
                              onPressed: () async {
                                controller.searchOperation(index);
                              },
                              child:
                                  controller.users[index]['buttonType'] == null
                                  ? Container(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.teal,
                                      ),
                                    )
                                  : MyText(
                                      text: controller
                                          .users[index]['buttonType']
                                          .toString(),
                                      color: Colors.teal,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
