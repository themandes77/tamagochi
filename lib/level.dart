import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter_application_1/actors/player.dart';

class Level extends Component {
    final Nti nt;

    Level(this.nt);

    @override
        FutureOr<void> onLoad() async {
            final soap = await Sprite.load("soap.png");
            final component = SpriteButtonComponent(
                    button: soap,
                    buttonDown: soap,
                    size: Vector2.all(150),
                    anchor: Anchor.center,
                    onPressed: () {
                        nt.wash();
                    }
                    );
            component.position = Vector2(80, 830);

            add(component);

            return super.onLoad();
        }
}
