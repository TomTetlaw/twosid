
imm_window_props :: struct {
    MaxHeight := -1.0;
}

ImmBeginWindow :: (Position: float2, Title: string, Props := imm_window_props.{}, Id := -1, L := #caller_location) {
    WidgetId := MakeWidgetId(Id, L);
    Window := GetOrCreateWidget(WidgetId, widget_window);
    
    Window.Position = Position;
    Window.LayoutPosition = Position + Window.GlobalMargin;
    Window.Size = Window.GlobalMargin;
    Window.LayoutMarkX = 0.0;
    Window.Props = Props;
    
    Assert(CurrentWindow == null);
    CurrentWindow = Window;
    
    ImmLabel(Title, IMMUI_TITLE_FONT_SIZE, TitleFont, Id + 1, L);
    ImmSeperator(Id + 2, L);
}

ImmEndWindow :: (Id := -1, L := #caller_location) {
    if CurrentWindow.Size.y > CurrentWindow.Props.MaxHeight {
        Diff := CurrentWindow.Size.y - CurrentWindow.Props.MaxHeight;
        
        if WidgetHovered(null, CurrentWindow.Position, CurrentWindow.Size) {
            CurrentWindow.GoalScrollOffsetY += Mouse.ScrollAxis * 16.0;
            CurrentWindow.GoalScrollOffsetY = Clamp(CurrentWindow.GoalScrollOffsetY, -Diff, 0);
            CurrentWindow.ScrollOffsetY = Approach(CurrentWindow.ScrollOffsetY, CurrentWindow.GoalScrollOffsetY, 0.25);
        }
        
        CurrentWindow.Size.y = CurrentWindow.Props.MaxHeight;
    }
    
    Assert(CurrentWindow != null);
    CurrentWindow = null;
}

ImmSeperator :: (Id := -1, L := #caller_location) {
    ImmRect(.{-1, 2}, IMMUI_SEPERATOR_COLOUR, Id, L);
}

ImmRect :: (Size: float2, Colour := IMMUI_BOX_COLOUR, Id := -1, L := #caller_location) {
    Assert(CurrentWindow != null);
    
    WidgetId := MakeWidgetId(Id, L);
    Rect := GetOrCreateWidget(WidgetId, widget_base);
    
    Rect.ParentId = CurrentWindow.Id;
    Rect.Position = GetLayoutPosition(CurrentWindow);
    Rect.Size = Size;
    Rect.Colour = Colour;
    
    AdvanceWindowLayoutPosition(CurrentWindow, Rect.Size);
}

ImmLabel :: (Text: string, FontSize := IMMUI_FONT_SIZE, Font: *sdf_font = null, Id := -1, L := #caller_location) {
    Assert(CurrentWindow != null);
    
    WidgetId := MakeWidgetId(Id, L);
    Label := GetOrCreateWidget(WidgetId, widget_label);
    
    Label.Position = GetLayoutPosition(CurrentWindow);
    Label.Size = GetStringSize(TextFont, FontSize, Text);
    Label.Text = Text;
    Label.FontSize = FontSize;
    Label.Font = ifx Font then Font else TextFont;
    
    AdvanceWindowLayoutPosition(CurrentWindow, Label.Size);
}

ImmButton :: (Text: string, FontSize := IMMUI_FONT_SIZE, Font: *sdf_font = null, Id := -1, L := #caller_location) -> bool {
    Assert(CurrentWindow != null);
    
    WidgetId := MakeWidgetId(Id, L);
    Button := GetOrCreateWidget(WidgetId, widget_button);
    
    Button.Position = GetLayoutPosition(CurrentWindow);
    Button.Size = GetStringSize(TextFont, FontSize, Text) + Button.TextMargin*2;
    Button.Text = Text;
    Button.Font = ifx Font then Font else TextFont;
    Button.FontSize = FontSize;
    
    AdvanceWindowLayoutPosition(CurrentWindow, Button.Size);
    
    return WidgetClicked(Button, Button.Position, Button.Size);
}

ImmBeginTree :: (Title: string, Id := -1, L := #caller_location) -> bool {
    Assert(CurrentWindow != null);
    
    WidgetId := MakeWidgetId(Id, L);
    Tree := GetOrCreateWidget(WidgetId, widget_tree);
    
    Text := TFormat("% [%]", Title, ifx Tree.Open "-" else "+");
    
    Tree.Position = GetLayoutPosition(CurrentWindow);
    Tree.Size = GetStringSize(TitleFont, IMMUI_TITLE_FONT_SIZE, Text) + Tree.TextMargin*2;
    Tree.Title = Text;
    Tree.Font = TitleFont;
    Tree.FontSize = IMMUI_TITLE_FONT_SIZE;
    
    Clicked := WidgetClicked(Tree, Tree.Position, Tree.Size);
    
    if Clicked Tree.Open = !Tree.Open;
    
    if Tree.Open AddLayoutMark(CurrentWindow, 8.0);
    
    AdvanceWindowLayoutPosition(CurrentWindow, Tree.Size);
    
    return Tree.Open;
}

ImmEndTree :: () {
    Assert(CurrentWindow != null);
    AddLayoutMark(CurrentWindow, -8.0);
}

UpdateUI :: () {
    GUIWantsInput = false;
    
    Windows := FilterWidgets(.WINDOW);
    for Widgets {
        if WidgetHovered(null, it.Position, it.Size) GUIWantsInput = true;
    }
}

DrawUI :: () {
    Windows := FilterWidgets(.WINDOW);
    Rects := FilterWidgets(.BASE);
    Labels := FilterWidgets(.LABEL);
    Buttons := FilterWidgets(.BUTTON);
    Trees := FilterWidgets(.TREE);
    
    for Windows {
        Assert(!it.DrawnThisFrame);
        it.DrawnThisFrame = true;
        
        Window := cast (*widget_window) it;
        
        Size := Window.Size;
        Size += Window.GlobalMargin * 2;
        DrawScreenSpaceQuad(Window.Position, Size, IMMUI_BOX_COLOUR, Options=.{Scissor=xyzw(Window.Position, Size)});
    }
    
    for Rects {
        Assert(!it.DrawnThisFrame);
        it.DrawnThisFrame = true;
        
        Position := GetDrawPosition(it);
        Size := GetDrawSize(it);
        DrawScreenSpaceQuad(Position, Size, it.Colour, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
    }
    
    for Labels {
        Assert(!it.DrawnThisFrame);
        it.DrawnThisFrame = true;
        
        Label := cast (*widget_label) it;
        
        Position := GetDrawPosition(Label);
        DrawTextSDF(Position, Label.Font, Label.FontSize, Label.Text, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
    }
    
    for Buttons {
        Assert(!it.DrawnThisFrame);
        it.DrawnThisFrame = true;
        
        Button := cast (*widget_button) it;
        
        Size := GetDrawSize(it);
        
        Colour := IMMUI_BOX_COLOUR;
        Hovered := WidgetHovered(Button, Button.Position, Size);
        
        if Hovered {
            Colour = IMMUI_BOX_COLOUR_HOVERED;
        }
        
        Position := GetDrawPosition(Button);
        DrawScreenSpaceQuad(Position, Size, Colour, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
        DrawTextSDF(Position + Button.TextMargin, Button.Font, Button.FontSize, Button.Text, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
    }
    
    for Trees {
        Assert(!it.DrawnThisFrame);
        it.DrawnThisFrame = true;
        
        Tree := cast (*widget_tree) it;
        
        Size := GetDrawSize(it);
        
        Colour := IMMUI_BOX_COLOUR;
        Hovered := WidgetHovered(Tree, Tree.Position, Size);
        
        if Hovered {
            Colour = IMMUI_BOX_COLOUR_HOVERED;
        }
        
        Position := GetDrawPosition(Tree);
        DrawScreenSpaceQuad(Position, Size, Colour, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
        DrawTextSDF(Position + Tree.TextMargin, Tree.Font, Tree.FontSize, Tree.Title, Options=.{Scissor=xyzw(it.Window.Position, it.Window.Size)});
    }
    
    for Widgets {
        it.UsedThisFrame = false;
        it.DrawnThisFrame = false;
    }
}

InitImmUI :: () {
    TextFont = LoadDistanceFont("fonts/consolas.png");
    TitleFont = LoadDistanceFont("fonts/liberation_mono.png");
}

GUIWantsInput := false;

#scope_file

widget_id :: int;

widget_kind :: enum {
    BASE;
    WINDOW;
    BUTTON;
    LABEL;
    TREE;
}

widget_base :: struct {
    Kind := widget_kind.BASE;
    Id, ParentId: widget_id;
    Position, Size: float2;
    Colour: float4;
    UsedThisFrame: bool;
    DrawnThisFrame: bool;
    Window: *widget_window;
}

widget_window :: struct {
#as using Base: widget_base;
    Base.Kind = .WINDOW;
    
    LayoutPosition: float2;
    GlobalMargin := float2.{4, 4};
    LocalMarginY := 4;
    Props: imm_window_props;
    
    GoalScrollOffsetY := 0.0;
    ScrollOffsetY := 0.0;
    
    LayoutMarkX: float;
}

widget_label :: struct {
#as using Base: widget_base;
    Base.Kind = .LABEL;
    
    Text: string;
    Font: *sdf_font;
    FontSize: float;
}

widget_button :: struct {
#as using Base: widget_base;
    Base.Kind = .BUTTON;
    
    TextMargin := float2.{2, 2};
    Text: string;
    Font: *sdf_font;
    FontSize: float;
}

widget_tree :: struct {
#as using Base: widget_base;
    Base.Kind = .TREE;
    
    TextMargin := float2.{2, 2};
    Title: string;
    Font: *sdf_font;
    FontSize: float;
    
    Open: bool;
}

GetDrawPosition :: (Widget: *widget_base) -> float2 {
    return Widget.Position + float2.{0, Widget.Window.ScrollOffsetY};
}

GetDrawSize :: (Widget: *widget_base) -> float2 {
    Parent := GetWidget(Widget.ParentId);
    
    if Parent {
        Size := Widget.Size;
        if Size.x == -1 Size.x = Parent.Size.x;
        if Size.y == -1 Size.y = Parent.Size.y;
        return Size;
    }
    
    return Widget.Size;
}

GetLayoutPosition :: (Window: *widget_window) -> float2 {
    return Window.LayoutPosition + .{Window.LayoutMarkX, 0};
}

AdvanceWindowLayoutPosition :: (Window: *widget_window, Size: float2) {
    TotalSize := float2.{Size.x + Window.GlobalMargin.x*2, Size.y + Window.LocalMarginY};
    
    Window.LayoutPosition.y += TotalSize.y;
    
    Window.Size.x = Max(Window.Size.x, TotalSize.x);
    Window.Size.y += TotalSize.y;
}

AddLayoutMark :: (Window: *widget_window, Mark: float) {
    Window.LayoutMarkX = Max(Window.LayoutMarkX + Mark, 0.0);
}

CurrentWindow: *widget_window;

MakeWidgetId :: (Id: int, L: Source_Code_Location) -> widget_id {
    Hash := GetHash(L.fully_pathed_filename);
    Hash = GetHash(L.line_number, Hash);
    Hash = GetHash(Id, Hash);
    return cast(int) Hash;
}

GetOrCreateWidget :: (Id: widget_id, $T: Type) -> *T {
    for Widgets {
        if it.Id == Id {
            Assert(!it.UsedThisFrame);
            it.UsedThisFrame = true;
            return cast (*T) it;
        }
    }
    
    Widget := ArenaPush(*UIArena, T);
    Widget.Id = Id;
    Widget.Window = CurrentWindow;
    
    ArenaPush(*Widgets, Widget);
    
    return Widget;
}

GetWidget :: (Id: widget_id) -> *widget_base {
    for Widgets {
        if it.Id == Id {
            it.UsedThisFrame = true;
            return it;
        }
    }
    
    return null;
}

FilterWidgets :: (Kind: widget_kind) -> [] *widget_base {
    Mark := ArenaPushMark(*FrameArena);
    
    for Widgets {
        if !it.UsedThisFrame continue;
        if it.Kind == Kind ArenaPush(*FrameArena, *widget_base, it);
    }
    
    return ArenaToView(*FrameArena, *widget_base, Mark, FrameArena.Used - Mark);
}

WidgetClicked :: (Widget: *widget_base, Position: float2, Size: float2) -> bool {
    P := Position;
    if Widget P += float2.{0, Widget.Window.ScrollOffsetY};
    
    Box := bounding_box_2d.{P, P + Size};
    
    for FrameClicks {
        if PointIntersectsBox(Mouse.Position, Box) return true;
    }
    
    return false;
}

WidgetHovered :: (Widget: *widget_base, Position: float2, Size: float2) -> bool {
    P := Position;
    if Widget P += float2.{0, Widget.Window.ScrollOffsetY};
    
    Box := bounding_box_2d.{P, P + Size};
    
    if PointIntersectsBox(Mouse.Position, Box) return true;
    return false;
}

UIArena: arena;
Widgets: arena(*widget_base);

TextFont: *sdf_font;
TitleFont: *sdf_font;

IMMUI_BOX_COLOUR :: #run rgba(194, 123, 2, 102);
IMMUI_BOX_COLOUR_HOVERED :: #run rgba(194, 123, 2, 204);
IMMUI_SEPERATOR_COLOUR :: #run rgba(194+50, 123+50, 2+50, 200);

IMMUI_FONT_SIZE :: 16.0;
IMMUI_TITLE_FONT_SIZE :: 20.0;