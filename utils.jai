
fatal_error :: (format: string, args: ..Any) {
    builder: String_Builder;
    print_to_builder(*builder, format, ..args);
    message := builder_to_string(*builder);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error!", message.data, null);
    exit(0);
}

sdl_get_error :: () -> string {
    return to_string(SDL_GetError());
}

sdl_get_gpu_device_driver :: (device: *SDL_GPUDevice) -> string {
    return to_string(SDL_GetGPUDeviceDriver(device));
}

#scope_file

#import "Basic";