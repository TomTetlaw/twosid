
CreateVertexBuffer :: (Device: *SDL_GPUDevice, Name: string, Stride: int, Elements: int) -> *SDL_GPUBuffer {
    VertexCreateInfo: SDL_GPUBufferCreateInfo;
    VertexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    VertexCreateInfo.size = xx (Stride * Elements);
    Buffer := SDL_CreateGPUBuffer(Device, *VertexCreateInfo);
    SDL_SetGPUBufferName(Device, Buffer, Name.data);
    return Buffer;
}

CreateIndexBuffer :: (Device: *SDL_GPUDevice, Name: string, Elements: int) -> *SDL_GPUBuffer {
    IndexCreateInfo: SDL_GPUBufferCreateInfo;
    IndexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_INDEX;
    IndexCreateInfo.size = xx (Elements * size_of(u32));
    Buffer := SDL_CreateGPUBuffer(Device, *IndexCreateInfo);
    SDL_SetGPUBufferName(Device, Buffer, Name.data);
    return Buffer;
}

CreateBuffer :: (Name: string, Size: int, Usage: SDL_GPUBufferUsageFlags) -> *SDL_GPUBuffer {
    CreateInfo: SDL_GPUBufferCreateInfo;
    CreateInfo.usage = Usage;
    CreateInfo.size = xx Size;
    Buffer := SDL_CreateGPUBuffer(GDevice, *CreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, Name.data);
    return Buffer;
}

CreateTransferBuffer :: (Size: int) -> *SDL_GPUTransferBuffer {
    TransferCreateInfo: SDL_GPUTransferBufferCreateInfo;
    TransferCreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    TransferCreateInfo.size = xx Size;
    return SDL_CreateGPUTransferBuffer(GDevice, *TransferCreateInfo);
}