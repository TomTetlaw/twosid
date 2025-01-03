
HandleUIInput :: () {
    if !GIsUIOpen return;
    
    RootChanged := false;
    
    if RootNode.Left && KeyPressed(.SDL_SCANCODE_A) {
        AddToStack();
        RootNode = RootNode.Left;
        RootChanged = true;
    }
    
    if RootNode.Right && KeyPressed(.SDL_SCANCODE_D) {
        AddToStack();
        RootNode = RootNode.Right;
        RootChanged = true;
    }
    
    if RootNode.Up && KeyPressed(.SDL_SCANCODE_W) {
        AddToStack();
        RootNode = RootNode.Up;
        RootChanged = true;
    }
    
    if RootNode.Down && KeyPressed(.SDL_SCANCODE_S) {
        AddToStack();
        RootNode = RootNode.Down;
        RootChanged = true;
    }
    
    if RootChanged && RootNode.Leaf {
        Selected = RootNode;
        CloseUI();
    }
    
    if KeyPressed(.SDL_SCANCODE_Q) {
        PopFromStack();
    }
}

UITextNode :: (Text: string, Id := -1, Children: [] *select_node = .[]) -> *select_node {
    Node := ArenaPush(*Elements);
    Node.Id = Id;
    Node.Leaf = Children.count <= 0;
    if Children.count > 0 Node.Left = Children[0];
    if Children.count > 1 Node.Right = Children[1];
    if Children.count > 2 Node.Up = Children[2];
    if Children.count > 3 Node.Down = Children[3];
    Node.Text = Text;
    return Node;
}

UIImageNode :: (Image: *texture, Id := -1, Children: [] *select_node = .[]) -> *select_node {
    Node := ArenaPush(*Elements);
    Node.Id = Id;
    Node.Leaf = Children.count <= 0;
    if Children.count > 0 Node.Left = Children[0];
    if Children.count > 1 Node.Right = Children[1];
    if Children.count > 2 Node.Up = Children[2];
    if Children.count > 3 Node.Down = Children[3];
    Node.Image = Image;
    return Node;
}

GetSelectedUINodeId :: () -> int {
    if !Selected return -1;
    
    Id := Selected.Id;
    Selected = null;
    return Id;
}

DrawUI :: () {
    if !GIsUIOpen return;
    
    WindowCenter := float2.{1366, 768} * .5;
    
    Size := GetStringSize(TextFont, IMMUI_FONT_SIZE, RootNode.Text);
    DrawTextSDF(WindowCenter - Size*.5, TextFont, IMMUI_FONT_SIZE, RootNode.Text);
    
    if RootNode.Left {
        LeftPos := WindowCenter + .{-128, 0};
        LeftSize := GetStringSize(TextFont, IMMUI_FONT_SIZE, RootNode.Left.Text);
        DrawScreenSpaceQuad(LeftPos, .{64, 64}, .{.5, .5, .5, 1.0});
        DrawTextSDF(LeftPos - Size*.5, TextFont, IMMUI_FONT_SIZE, RootNode.Left.Text);
    }
    
    if RootNode.Right {
        RightPos := WindowCenter + .{128, 0};
        RightSize := GetStringSize(TextFont, IMMUI_FONT_SIZE, RootNode.Right.Text);
        DrawScreenSpaceQuad(RightPos, .{64, 64}, .{.5, .5, .5, 1.0});
        DrawTextSDF(RightPos - Size*.5, TextFont, IMMUI_FONT_SIZE, RootNode.Right.Text);
    }
    
    if RootNode.Up {
        UpPos := WindowCenter + .{0, -128};
        UpSize := GetStringSize(TextFont, IMMUI_FONT_SIZE, RootNode.Up.Text);
        DrawScreenSpaceQuad(UpPos, .{64, 64}, .{.5, .5, .5, 1.0});
        DrawTextSDF(UpPos - Size*.5, TextFont, IMMUI_FONT_SIZE, RootNode.Up.Text);
    }
    
    if RootNode.Down {
        DownPos := WindowCenter + .{0, 128};
        DownSize := GetStringSize(TextFont, IMMUI_FONT_SIZE, RootNode.Down.Text);
        DrawScreenSpaceQuad(DownPos, .{64, 64}, .{.5, .5, .5, 1.0});
        DrawTextSDF(DownPos - Size*.5, TextFont, IMMUI_FONT_SIZE, RootNode.Down.Text);
    }
    
    Selected = null;
}

InitUISystem :: () {
    TextFont = LoadDistanceFont("fonts/roboto.png");
    PrevNodes = ArenaPushN(*UIArena, *select_node, 1024);
}

OpenUI :: (Root: *select_node) {
    GIsUIOpen = true;
    RootNode = Root;
    PrevNodes.count = 0;
}

CloseUI :: () {
    GIsUIOpen = false;
    RootNode = null;
}

GIsUIOpen := false;

select_node :: struct {
    Id: int;
    Left, Right, Up, Down: *select_node;
    Text: string;
    Image: *texture;
    Leaf: bool;
}

#scope_file

UIArena: arena;
Elements: arena(select_node);

TextFont: *sdf_font;

IMMUI_FONT_SIZE :: 16.0;

AddToStack :: () {
    if PrevNodes.count == 1024 return;
    
    PrevNodes.count += 1;
    PrevNodes[PrevNodes.count - 1] = RootNode;
}

PopFromStack :: () {
    if PrevNodes.count == 0 {
        CloseUI();
        return;
    }
    
    RootNode = PrevNodes[PrevNodes.count - 1];
    PrevNodes.count -= 1;
}

Selected: *select_node;
RootNode: *select_node;
PrevNodes: [] *select_node;