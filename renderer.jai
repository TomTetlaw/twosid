
init_renderer :: (device: *SDL_GPUDevice, w: *SDL_Window) {
    gpu_device = device;
    window = w;
}

draw_frame :: () {
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    
    swap_texture: *SDL_GPUTexture;
    SDL_AcquireGPUSwapchainTexture(command_buffer, window, *swap_texture, null, null);
    
    target_info: SDL_GPUColorTargetInfo;
    target_info.texture = swap_texture;
    target_info.clear_color = .{1, 0, 0, 1};
    target_info.load_op = .SDL_GPU_LOADOP_CLEAR;
    target_info.store_op = .SDL_GPU_STOREOP_STORE;
    
    render_pass := SDL_BeginGPURenderPass(command_buffer, *target_info, 1, null);
    SDL_EndGPURenderPass(render_pass);
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
}

#scope_file

gpu_device: *SDL_GPUDevice;
window: *SDL_Window;