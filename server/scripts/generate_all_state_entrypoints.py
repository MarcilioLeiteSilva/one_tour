#!/usr/bin/env python3
"""
One Tour - 27 States Industrialization Automation Script
Generates Flutter entrypoints (lib/main_{uf}.dart) and asset directories
(assets/flavors/{uf}/) for all 27 Brazilian states.
"""

import os

ALL_STATES = [
    ("pe", "Pernambuco"),
    ("sp", "São Paulo"),
    ("rj", "Rio de Janeiro"),
    ("ba", "Bahia"),
    ("mg", "Minas Gerais"),
    ("ce", "Ceará"),
    ("pr", "Paraná"),
    ("sc", "Santa Catarina"),
    ("rs", "Rio Grande do Sul"),
    ("al", "Alagoas"),
    ("pb", "Paraíba"),
    ("rn", "Rio Grande do Norte"),
    ("se", "Sergipe"),
    ("ma", "Maranhão"),
    ("pi", "Piauí"),
    ("es", "Espírito Santo"),
    ("go", "Goiás"),
    ("df", "Distrito Federal"),
    ("mt", "Mato Grosso"),
    ("ms", "Mato Grosso do Sul"),
    ("am", "Amazonas"),
    ("pa", "Pará"),
    ("to", "Tocantins"),
    ("ro", "Rondônia"),
    ("ac", "Acre"),
    ("ap", "Amapá"),
    ("rr", "Roraima"),
]

def generate_entrypoints(mobile_dir):
    lib_dir = os.path.join(mobile_dir, "lib")
    flavors_asset_dir = os.path.join(mobile_dir, "assets", "flavors")

    os.makedirs(lib_dir, exist_ok=True)
    os.makedirs(flavors_asset_dir, exist_ok=True)

    generated_entrypoints = 0
    generated_assets = 0

    for uf, state_name in ALL_STATES:
        # 1. Entrypoint file: lib/main_{uf}.dart
        entrypoint_path = os.path.join(lib_dir, f"main_{uf}.dart")
        content = f"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor.dart';

/// Entrypoint específico para compilar e rodar o flavor Tour {state_name} ({uf.upper()})
void main() {{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith((ref) => AppFlavor.{uf}),
      ],
      child: const OneTourApp(),
    ),
  );
}}
"""
        with open(entrypoint_path, "w", encoding="utf-8") as f:
            f.write(content)
        generated_entrypoints += 1

        # 2. Asset directory: assets/flavors/{uf}/
        state_asset_dir = os.path.join(flavors_asset_dir, uf)
        os.makedirs(state_asset_dir, exist_ok=True)
        readme_path = os.path.join(state_asset_dir, "README.md")
        if not os.path.exists(readme_path):
            with open(readme_path, "w", encoding="utf-8") as f:
                f.write(f"# Assets para Tour {state_name} ({uf.upper()})\n\nColoque aqui ícones, brasões e imagens específicas do estado.\n")
            generated_assets += 1

    print(f"SUCCESS: Generated {generated_entrypoints} entrypoint files and asset directories for all 27 Brazilian states!")

if __name__ == "__main__":
    base_mobile = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "mobile"))
    generate_entrypoints(base_mobile)
