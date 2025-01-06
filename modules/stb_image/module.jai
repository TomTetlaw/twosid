
#if OS == .WINDOWS {
    FILE :: void;
#load "windows.jai";
} else {
#load "linux.jai";
}