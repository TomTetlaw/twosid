
create_and_map_buffer :: (device: *SDL_GPUDevice, name: string, size: int, usage: SDL_GPUBufferUsageFlags) -> *SDL_GPUBuffer, *SDL_GPUTransferBuffer, *u8 {
    create_info: SDL_GPUBufferCreateInfo;
    create_info.usage = usage;
    create_info.size = xx size;
    buffer := SDL_CreateGPUBuffer(device, *create_info);
    SDL_SetGPUBufferName(device, buffer, name.data);
    
    transfer_create_info: SDL_GPUTransferBufferCreateInfo;
    transfer_create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    transfer_create_info.size = xx size;
    transfer_buffer := SDL_CreateGPUTransferBuffer(device, *transfer_create_info);
    
    memory := SDL_MapGPUTransferBuffer(g_device, transfer_buffer, false);
    return buffer, transfer_buffer, memory;
}

commit_mapped_buffer :: (device: *SDL_GPUDevice, buffer: *SDL_GPUBuffer, transfer_buffer: *SDL_GPUTransferBuffer, size: int) {
    SDL_UnmapGPUTransferBuffer(device, transfer_buffer);
    
    command_buffer := SDL_AcquireGPUCommandBuffer(device);
    copy_pass := SDL_BeginGPUCopyPass(command_buffer);
    
    location: SDL_GPUTransferBufferLocation;
    location.transfer_buffer = transfer_buffer;
    location.offset = 0;
    
    region: SDL_GPUBufferRegion;
    region.buffer = buffer;
    region.offset = 0;
    region.size = xx size;
    
    SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
    
    SDL_EndGPUCopyPass(copy_pass);
    SDL_SubmitGPUCommandBuffer(command_buffer);
    SDL_ReleaseGPUTransferBuffer(device, transfer_buffer);
}

create_vertex_buffer :: (device: *SDL_GPUDevice, name: string, stride: int, elements: int) -> *SDL_GPUBuffer {
    vertex_create_info: SDL_GPUBufferCreateInfo;
    vertex_create_info.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    vertex_create_info.size = xx (stride * elements);
    buffer := SDL_CreateGPUBuffer(device, *vertex_create_info);
    SDL_SetGPUBufferName(device, buffer, name.data);
    return buffer;
}

create_index_buffer :: (device: *SDL_GPUDevice, name: string, elements: int) -> *SDL_GPUBuffer {
    index_create_info: SDL_GPUBufferCreateInfo;
    index_create_info.usage = SDL_GPU_BUFFERUSAGE_INDEX;
    index_create_info.size = xx (elements * size_of(u32));
    buffer := SDL_CreateGPUBuffer(device, *index_create_info);
    SDL_SetGPUBufferName(device, buffer, name.data);
    return buffer;
}

create_instance_buffer :: (device: *SDL_GPUDevice, name: string, data: [] $T) -> *SDL_GPUBuffer {
    instance_buffer, transfer_buffer, memory := create_and_map_buffer(device, name, size_of(T) * MAX_INSTANCES, SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ);
    memcpy(memory, data.data, size_of(T) * data.count);
    commit_mapped_buffer(device, instance_buffer, transfer_buffer, size_of(T) * data.count);
    return instance_buffer;
}