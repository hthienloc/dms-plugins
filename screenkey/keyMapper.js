const KEY_MAP = {
    "KEY_A": "A", "KEY_B": "B", "KEY_C": "C", "KEY_D": "D", "KEY_E": "E",
    "KEY_F": "F", "KEY_G": "G", "KEY_H": "H", "KEY_I": "I", "KEY_J": "J",
    "KEY_K": "K", "KEY_L": "L", "KEY_M": "M", "KEY_N": "N", "KEY_O": "O",
    "KEY_P": "P", "KEY_Q": "Q", "KEY_R": "R", "KEY_S": "S", "KEY_T": "T",
    "KEY_U": "U", "KEY_V": "V", "KEY_W": "W", "KEY_X": "X", "KEY_Y": "Y",
    "KEY_Z": "Z",
    "KEY_0": "0", "KEY_1": "1", "KEY_2": "2", "KEY_3": "3", "KEY_4": "4",
    "KEY_5": "5", "KEY_6": "6", "KEY_7": "7", "KEY_8": "8", "KEY_9": "9",
    "KEY_SPACE": "Space",
    "KEY_ENTER": "Enter", "KEY_KPENTER": "Enter",
    "KEY_TAB": "Tab",
    "KEY_BACKSPACE": "Backspace",
    "KEY_ESC": "Esc",
    "KEY_UP": "↑", "KEY_DOWN": "↓", "KEY_LEFT": "←", "KEY_RIGHT": "→",
    "KEY_MINUS": "-", "KEY_EQUAL": "=",
    "KEY_LEFTBRACE": "[", "KEY_RIGHTBRACE": "]",
    "KEY_SEMICOLON": ";", "KEY_APOSTROPHE": "'",
    "KEY_GRAVE": "`",
    "KEY_BACKSLASH": "\\",
    "KEY_COMMA": ",", "KEY_DOT": ".", "KEY_SLASH": "/",
    "KEY_CAPSLOCK": "Caps Lock",
    "KEY_PAGEUP": "PgUp", "KEY_PAGEDOWN": "PgDown",
    "KEY_INSERT": "Ins", "KEY_DELETE": "Del",
    "KEY_HOME": "Home", "KEY_END": "End",
    "KEY_F1": "F1", "KEY_F2": "F2", "KEY_F3": "F3", "KEY_F4": "F4",
    "KEY_F5": "F5", "KEY_F6": "F6", "KEY_F7": "F7", "KEY_F8": "F8",
    "KEY_F9": "F9", "KEY_F10": "F10", "KEY_F11": "F11", "KEY_F12": "F12"
};

const CHAR_MAP = {
    "KEY_A": "a", "KEY_B": "b", "KEY_C": "c", "KEY_D": "d", "KEY_E": "e",
    "KEY_F": "f", "KEY_G": "g", "KEY_H": "h", "KEY_I": "i", "KEY_J": "j",
    "KEY_K": "k", "KEY_L": "l", "KEY_M": "m", "KEY_N": "n", "KEY_O": "o",
    "KEY_P": "p", "KEY_Q": "q", "KEY_R": "r", "KEY_S": "s", "KEY_T": "t",
    "KEY_U": "u", "KEY_V": "v", "KEY_W": "w", "KEY_X": "x", "KEY_Y": "y",
    "KEY_Z": "z",
    "KEY_0": "0", "KEY_1": "1", "KEY_2": "2", "KEY_3": "3", "KEY_4": "4",
    "KEY_5": "5", "KEY_6": "6", "KEY_7": "7", "KEY_8": "8", "KEY_9": "9",
    "KEY_SPACE": " ",
    "KEY_MINUS": "-", "KEY_EQUAL": "=",
    "KEY_LEFTBRACE": "[", "KEY_RIGHTBRACE": "]",
    "KEY_SEMICOLON": ";", "KEY_APOSTROPHE": "'",
    "KEY_GRAVE": "`",
    "KEY_BACKSLASH": "\\",
    "KEY_COMMA": ",", "KEY_DOT": ".", "KEY_SLASH": "/"
};

const SHIFT_CHAR_MAP = {
    "KEY_A": "A", "KEY_B": "B", "KEY_C": "C", "KEY_D": "D", "KEY_E": "E",
    "KEY_F": "F", "KEY_G": "G", "KEY_H": "H", "KEY_I": "I", "KEY_J": "J",
    "KEY_K": "K", "KEY_L": "L", "KEY_M": "M", "KEY_N": "N", "KEY_O": "O",
    "KEY_P": "P", "KEY_Q": "Q", "KEY_R": "R", "KEY_S": "S", "KEY_T": "T",
    "KEY_U": "U", "KEY_V": "V", "KEY_W": "W", "KEY_X": "X", "KEY_Y": "Y",
    "KEY_Z": "Z",
    "KEY_0": ")", "KEY_1": "!", "KEY_2": "@", "KEY_3": "#", "KEY_4": "$",
    "KEY_5": "%", "KEY_6": "^", "KEY_7": "&", "KEY_8": "*", "KEY_9": "(",
    "KEY_MINUS": "_", "KEY_EQUAL": "+",
    "KEY_LEFTBRACE": "{", "KEY_RIGHTBRACE": "}",
    "KEY_SEMICOLON": ":", "KEY_APOSTROPHE": "\"",
    "KEY_GRAVE": "~",
    "KEY_BACKSLASH": "|",
    "KEY_COMMA": "<", "KEY_DOT": ">", "KEY_SLASH": "?"
};

function getDisplayKey(keyName) {
    return KEY_MAP[keyName] || keyName.replace("KEY_", "");
}

function getChar(keyName, shiftActive) {
    if (shiftActive) {
        return SHIFT_CHAR_MAP[keyName] || CHAR_MAP[keyName] || "";
    }
    return CHAR_MAP[keyName] || "";
}

function isModifier(keyName) {
    return keyName === "KEY_LEFTCTRL" || keyName === "KEY_RIGHTCTRL" ||
           keyName === "KEY_LEFTSHIFT" || keyName === "KEY_RIGHTSHIFT" ||
           keyName === "KEY_LEFTALT" || keyName === "KEY_RIGHTALT" ||
           keyName === "KEY_LEFTMETA" || keyName === "KEY_RIGHTMETA";
}
