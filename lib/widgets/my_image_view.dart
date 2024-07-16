import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

enum MyImageViewType { file, network, memory }

class MyImageView extends StatelessWidget {
  const MyImageView({
    super.key,
    this.image,
    this.imageType = MyImageViewType.file,
  });

  final String? image;
  final MyImageViewType imageType;

  ImageProvider _buildImageProvider(String src) {
    if (imageType == MyImageViewType.network) {
      return NetworkImage(src);
    }
    if (imageType == MyImageViewType.memory) {
      return MemoryImage(base64Decode(src));
    }
    return FileImage(File(src));
  }

  @override
  Widget build(BuildContext context) {
    return image != null
        ? GestureDetector(
            child: Image(image: _buildImageProvider(image!)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoView(
                    imageProvider: _buildImageProvider(image!),
                  ),
                ),
              );
            },
          )
        : Image.asset("assets/images/portrait.png");
  }
}
