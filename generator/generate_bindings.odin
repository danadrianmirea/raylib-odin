package generate

import "core:fmt"
import "core:os"
import "./bindgen"
// import "core:encoding/json"
import "./preprocessed/aux_data"

main :: proc() {
    options : bindgen.GeneratorOptions;
    {
        // odin default casing
        options.variableCase = bindgen.Case.Snake;
        options.functionCase = bindgen.Case.Snake;
        options.pseudoTypeCase = bindgen.Case.Pascal;

        options.enumValuePrefixes = {
            "FLAG_", "LOG_", "KEY_", "GAMEPAD_", "MOUSE_", "LOC_",
            "UNIFORM_", "MAP_", "FONT_", "GESTURE_", "CAMERA_", "HMD_",
            "BLEND_",
        };

        using options.parserOptions;

        customExpressionHandlers["CLITERAL"] = cliteral_handler;
        customExpressionHandlers["Font"] = font_handler;
        customExpressionHandlers["Camera3D"] = camera3d_handler;


        ignoredTokens = []string{"RLAPI"};
    }

    args_map : bindgen.Enum_Args_Map = aux_data.get_enum_args();
    
    outputFile := "raylib_bindings/raylib_bindings.odin";
    typesFile := "raylib_types/raylib_types.odin";
    bridgeFile := "raylib_bridge/raylib_bridge.odin";

    ok := bindgen.generate(
        packageName = "raylib",
        foreignLibrary = "raylib.lib",
        outputFile = outputFile,
        typesFile = typesFile,
        bridgeFile = bridgeFile,
        headerFiles = []string{"./generator/preprocessed/raylib.h"},
        options = options,
        enum_args_map = args_map,
    );

    if ok {
        fmt.println("wrote", outputFile);
        fmt.println("wrote", typesFile);
        fmt.println("wrote", bridgeFile);
    }
}

cliteral_handler :: proc(data: ^bindgen.ParserData) -> bindgen.LiteralValue
{
    bindgen.check_and_eat_token(data, "CLITERAL");
    bindgen.check_and_eat_token(data, "{");
    r := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    g := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    b := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    a := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, "}");
    data.defining_node.is_variable = true;
    return fmt.tprintf("Color { %d, %d, %d, %d }", r, g, b, a);
}

macro_make_version :: proc(data : ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "VK_MAKE_VERSION");
    bindgen.check_and_eat_token(data, "(");
    major := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    minor := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    patch := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ")");

    return (((major) << 22) | ((minor) << 12) | (patch));
}

color_handler :: proc(data: ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "Color"); return "Color";
}

font_handler :: proc(data: ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "Font"); return "Font";
}

camera3d_handler :: proc(data: ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "Camera3D"); return "Camera3D";
}

_cliteral_handler :: proc(data: ^bindgen.ParserData) {
    fmt.println("HERE");
    bindgen.check_and_eat_token(data, "(");
    bindgen.parse_identifier(data);
    bindgen.check_and_eat_token(data, ")");
}

declspec_handler :: proc(data: ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "__declspec");
    bindgen.check_and_eat_token(data, "(");
    bindgen.parse_identifier(data);
    bindgen.check_and_eat_token(data, ")");
    return "";
}

