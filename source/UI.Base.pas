{*******************************************************}
{                                                       }
{       FMX UI ���Ļ�����Ԫ                             }
{                                                       }
{       ��Ȩ���� (C) 2016 YangYxd                       }
{                                                       }
{*******************************************************}

// ע�⣺��������ı���ʾ���������뽫patch�µ�
// FMX.TextLayout.GPU.pas �ŵ������ĿĿ¼��

unit UI.Base;

interface

{$SCOPEDENUMS ON}

{$IF CompilerVersion >= 29.0}
  {$DEFINE XE8_OR_NEWER}
{$ENDIF}

uses
  UI.Debug, UI.Utils,
  FMX.Forms,
  {$IFDEF ANDROID}
  Androidapi.Helpers,
  Androidapi.Jni,
  Androidapi.JNI.Media,
  Androidapi.JNIBridge,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Util,
  Androidapi.JNI.Os,
  FMX.Helpers.Android,
  {$ENDIF}
  {$IFDEF IOS}
  IOSApi.Foundation,
  {$ENDIF}
  FMX.BehaviorManager, FMX.StdActns, FMX.Menus,
  FMX.Styles, FMX.Styles.Objects,
  FMX.Utils, FMX.ImgList, FMX.MultiResBitmap, FMX.ActnList, System.Rtti, FMX.Consts,
  FMX.TextLayout, FMX.Objects, System.ImageList, System.RTLConsts,
  System.TypInfo, FMX.Graphics, System.Generics.Collections, System.Math, System.UIConsts,
  System.Classes, System.Types, System.UITypes, System.SysUtils, System.Math.Vectors,
  FMX.Types, FMX.StdCtrls, FMX.Platform, FMX.Controls, FMX.InertialMovement, FMX.Ani;

const
  AllCurrentPlatforms =
    pidWin32 or pidWin64 or pidOSX32 or
    pidiOSSimulator or pidiOSDevice or pidAndroid;

type
  IView = interface;
  IViewGroup = interface;
  TView = class;
  TViewGroup = class;

  TDrawableBase = class;
  TDrawable = class;
  TDrawableIcon = class;
  TViewColor = class;
  TDrawableBrush = class;

  EViewError = class(Exception);
  EViewLayoutError = class(Exception);
  EDrawableError = class(Exception);

  TViewClass = class of TControl;

  /// <summary>
  /// ��ͼ״̬
  /// </summary>
  TViewState = (None {����}, Pressed {����}, Focused {ȡ�ý���}, Hovered {��ͣ},
    Selected{ѡ��}, Checked{��ѡ}, Enabled{����}, Activated{����}, Custom {�Զ���});
  TViewStates = set of TViewState;

  /// <summary>
  /// ��ͼ��С
  /// </summary>
  TViewSize = (CustomSize {�Զ����С}, WrapContent {������}, FillParent {��丸��});
  /// <summary>
  /// ������
  /// </summary>
  TViewScroll = (None, Horizontal, Vertical, Both);

  TViewBrushKind = (None, Solid, Gradient, Bitmap, Resource, Patch9Bitmap, AccessoryBitmap);

  /// <summary>
  /// ��ͼ����
  /// </summary>
  TViewAccessoryType = (None, More, Checkmark, Detail, Ellipses, Flag, Back, Refresh,
    Action, Play, Rewind, Forwards, Pause, Stop, Add, Prior,
    Next, ArrowUp, ArrowDown, ArrowLeft, ArrowRight, Reply,
    Search, Bookmarks, Trash, Organize, Camera, Compose, Info,
    Pagecurl, Details, RadioButton, RadioButtonChecked, CheckBox,
    CheckBoxChecked, UserDefined1, UserDefined2, UserDefined3);

  TPatchBounds = class(TBounds);

  TRectFHelper = record Helper for TRectF
  public
    procedure Clear; inline;
  end;

  TControlHelper = class Helper for TControl
  public
    // Ϊָ���ؼ����ý���
    function SetFocusObject(V: TControl): Boolean;
    // ������һ������ؼ�
    procedure FocusToNext();
  end;

  { ��л  KernowSoftwareFMX }
  TViewAccessoryImageList = class(TObjectList<TBitmap>)
  private
    FImageScale: Single;
    FImageMap: TBitmap;
    FActiveStyle: TFmxObject;
    procedure AddEllipsesAccessory;
    procedure AddFlagAccessory;
    procedure AddBackAccessory;
    procedure CalculateImageScale;
    function GetAccessoryFromResource(const AStyleName: string; const AState: string = ''): TBitmap;
    procedure Initialize;
  public
    constructor Create;
    destructor Destroy; override;

    function GetAccessoryImage(AAccessory: TViewAccessoryType): TBitmap;
    procedure SetAccessoryImage(AAccessory: TViewAccessoryType; const Value: TBitmap);

    procedure Draw(ACanvas: TCanvas; const ARect: TRectF; AAccessory: TViewAccessoryType;
      const AOpacity: Single = 1; const AStretch: Boolean = True);

    property Images[AAccessory: TViewAccessoryType]: TBitmap read GetAccessoryImage write SetAccessoryImage; default;
    property ImageMap: TBitmap read FImageMap;
    property ImageScale: single read FImageScale;
  end;

  /// <summary>
  /// 9 ����λͼ
  /// </summary>
  TPatch9Bitmap = class(TBrushBitmap)
  private
    FBounds: TPatchBounds;
    FRemoveBlackLine: Boolean;
    procedure SetBounds(const Value: TPatchBounds);
    procedure SetRemoveBlackLine(const Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Bounds: TPatchBounds read FBounds write SetBounds;
    // �Ƿ��Ƴ�����(.9.pngһ�����һ�����ߣ��Ƴ�ʱ�������ǽ�ԭͼ�ص�����Χ��1����)
    property BlackLine: Boolean read FRemoveBlackLine write SetRemoveBlackLine default False;
  end;

  TViewBrushBase = class(TBrush)
  private
    FAccessoryType: TViewAccessoryType;
    FAccessoryBmp: TBitmap;
    FAccessoryColor: TAlphaColor;
    procedure SetAccessoryType(const Value: TViewAccessoryType);
    function GetKind: TViewBrushKind;
    procedure SetKind(const Value: TViewBrushKind);
    function IsKindStored: Boolean;
    procedure SetAccessoryColor(const Value: TAlphaColor);
  protected
    procedure DoAccessoryChange;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property AccessoryType: TViewAccessoryType read FAccessoryType write SetAccessoryType default TViewAccessoryType.None;
    property AccessoryColor: TAlphaColor read FAccessoryColor write SetAccessoryColor default 0;
    property Kind: TViewBrushKind read GetKind write SetKind stored IsKindStored;
  end;

  TViewBrush = class(TViewBrushBase)
  private
    function IsPatch9BitmapStored: Boolean;
    function GetBitmap: TPatch9Bitmap;
    procedure SetBitmap(const Value: TPatch9Bitmap);
  protected
  public
    constructor Create(const ADefaultKind: TViewBrushKind; const ADefaultColor: TAlphaColor);
  published
    property Bitmap: TPatch9Bitmap read GetBitmap write SetBitmap stored IsPatch9BitmapStored;
  end;

  TCustomActionEx = class(FMX.Menus.TMenuItem);

  TViewImagesBrush = class(TViewBrushBase, IInterface, IGlyph, IInterfaceComponentReference)
  private
    FImageIndex: TImageIndex;
    [Weak] FOwner: TObject;
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    { IInterfaceComponentReference }
    function GetComponent: TComponent;
    {IGlyph}
    function GetImageIndex: TImageIndex;
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
    procedure ImagesChanged; virtual;
    function GetImageList: TBaseImageList; inline;
    procedure SetImageList(const Value: TBaseImageList);
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
  public
    constructor Create(const ADefaultKind: TBrushKind; const ADefaultColor: TAlphaColor);
    property Owner: TObject read FOwner write FOwner;
    property Images: TBaseImageList read GetImageList write SetImageList;
  published
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
  end;

  /// <summary>
  /// ����λ��
  /// </summary>
  TDrawablePosition = (Left, Right, Top, Bottom, Center);

  /// <summary>
  /// �ɻ��ƶ���
  /// </summary>
  TDrawableBase = class(TPersistent)
  private
    FOnChanged: TNotifyEvent;

    FDefaultColor: TAlphaColor;
    FDefaultKind: TViewBrushKind;


    FXRadius, FYRadius: Single;
    FIsEmpty: Boolean;

    FCorners: TCorners;
    FCornerType: TCornerType;

    procedure GetStateBrush(const State: TViewState; var V: TBrush); overload;
    procedure SetStateBrush(const State: TViewState; const V: TBrush);
    procedure SetXRadius(const Value: Single);
    procedure SetYRadius(const Value: Single);
    procedure SetCorners(const Value: TCorners);
    function IsStoredCorners: Boolean;
    procedure SetCornerType(const Value: TCornerType);
  protected
    [Weak] FView: IView;
    FDefault: TBrush;
    FPressed: TBrush;
    FFocused: TBrush;
    FHovered: TBrush;
    FSelected: TBrush;
    FChecked: TBrush;
    FEnabled: TBrush;
    FActivated: TBrush;

    function GetEmpty: Boolean; virtual;
    function GetDrawRect(const ALeft, ATop, ARight, ABottom: Single): TRectF; virtual;
    function GetValue(const Index: Integer): TBrush;
    procedure SetValue(const Index: Integer; const Value: TBrush);

    procedure DoChange(Sender: TObject);

    class procedure FillRect9Patch(Canvas: TCanvas; const ARect: TRectF; const XRadius, YRadius: Single; const ACorners: TCorners;
      const AOpacity: Single; const ABrush: TViewBrush; const ACornerType: TCornerType = TCornerType.Round);
    procedure FillRect(Canvas: TCanvas; const ARect: TRectF; const XRadius, YRadius: Single; const ACorners: TCorners;
      const AOpacity: Single; const ABrush: TBrush; const ACornerType: TCornerType = TCornerType.Round); inline;
    procedure FillArc(Canvas: TCanvas; const Center, Radius: TPointF;
      const StartAngle, SweepAngle, AOpacity: Single; const ABrush: TBrush); inline;

    procedure DoDrawed(Canvas: TCanvas; var R: TRectF; AState: TViewState); virtual;
    procedure InitDrawable; virtual;
  public
    constructor Create(View: IView; const ADefaultKind: TViewBrushKind = TViewBrushKind.None;
      const ADefaultColor: TAlphaColor = TAlphaColors.Null);
    destructor Destroy; override;

    function BrushIsEmpty(V: TBrush): Boolean;

    function GetBrush(const State: TViewState; AutoCreate: Boolean): TBrush;
    function GetStateBrush(const State: TViewState): TBrush; overload;
    function GetStateItem(AState: TViewState): TBrush;
    function GetStateImagesItem(AState: TViewState): TBrush;

    procedure Assign(Source: TPersistent); override;
    procedure Change; virtual;
    procedure CreateBrush(var Value: TBrush; IsDefault: Boolean); overload; virtual;
    function CreateBrush(): TBrush; overload;

    procedure Draw(Canvas: TCanvas); virtual;
    procedure DrawTo(Canvas: TCanvas; const R: TRectF); inline;
    procedure DrawStateTo(Canvas: TCanvas; const R: TRectF; AState: TViewState); virtual;
    procedure DrawBrushTo(Canvas: TCanvas; ABrush: TBrush; const R: TRectF);

    procedure SetRadius(const X, Y: Single);
    procedure SetDrawable(const Value: TDrawableBase); overload;
    procedure SetBrush(State: TViewState; const Value: TBrush); overload;
    procedure SetBrush(State: TViewState; const Value: TDrawableBrush); overload;
    procedure SetColor(State: TViewState; const Value: TAlphaColor); overload;
    procedure SetGradient(State: TViewState; const Value: TGradient); overload;
    procedure SetBitmap(State: TViewState; const Value: TBitmap); overload;
    procedure SetBitmap(State: TViewState; const Value: TBrushBitmap); overload;

    // �Ƿ�Ϊ��
    property IsEmpty: Boolean read FIsEmpty;

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    // �߿�Բ��
    property XRadius: Single read FXRadius write SetXRadius;
    property YRadius: Single read FYRadius write SetYRadius;
    property Corners: TCorners read FCorners write SetCorners stored IsStoredCorners;
    property CornerType: TCornerType read FCornerType write SetCornerType default TCornerType.Round;
  end;

  /// <summary>
  /// �ɻ��ƶ���
  /// </summary>
  TDrawable = class(TDrawableBase)
  private
    FPadding: TBounds;
    procedure SetPadding(const Value: TBounds);
    function GetPaddings: string;
    procedure SetPaddings(const Value: string);
    function GetValue(const Index: Integer): TViewBrush;
    procedure SetValue(const Index: Integer; const Value: TViewBrush);
  protected
    function GetDrawRect(const ALeft, ATop, ARight, ABottom: Single): TRectF; override;
  public
    constructor Create(View: IView; const ADefaultKind: TViewBrushKind = TViewBrushKind.None;
      const ADefaultColor: TAlphaColor = TAlphaColors.Null);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Padding: TBounds read FPadding write SetPadding;
    property Paddings: string read GetPaddings write SetPaddings stored False;

    property XRadius;
    property YRadius;
    property Corners;
    property CornerType;
    property ItemDefault: TViewBrush index 0 read GetValue write SetValue;
    property ItemPressed: TViewBrush index 1 read GetValue write SetValue;
    property ItemFocused: TViewBrush index 2 read GetValue write SetValue;
    property ItemHovered: TViewBrush index 3 read GetValue write SetValue;
    property ItemSelected: TViewBrush index 4 read GetValue write SetValue;
    property ItemChecked: TViewBrush index 5 read GetValue write SetValue;
    property ItemEnabled: TViewBrush index 6 read GetValue write SetValue;
    property ItemActivated: TViewBrush index 7 read GetValue write SetValue;
  end;

  /// <summary>
  /// �߿���ʽ
  /// </summary>
  TViewBorderStyle = (None {�ޱ߿�},
    RectBorder {���ܾ��α߿�,��ʹ��Բ������},
    RectBitmap {ʵ�ĵľ���, ���},
    LineEdit {�ײ��߿򣨴�����͹��},
    LineTop {�����߿�},
    LineBottom {�ײ��߿�},
    LineLeft {��߱߿�},
    LineRight {�ұ߱߿�} );

  TViewBorder = class(TPersistent)
  private
    FOnChanged: TNotifyEvent;
    FBrush: TStrokeBrush;
    FColor: TViewColor;
    FStyle: TViewBorderStyle;
    FDefaultStyle: TViewBorderStyle;
    procedure SetColor(const Value: TViewColor);
    procedure SetStyle(const Value: TViewBorderStyle);
    procedure SetWidth(const Value: Single);
    procedure SetOnChanged(const Value: TNotifyEvent);
    function GetDash: TStrokeDash;
    function GetWidth: Single;
    procedure SetDash(const Value: TStrokeDash);
    function GetCap: TStrokeCap;
    function GetJoin: TStrokeJoin;
    procedure SetCap(const Value: TStrokeCap);
    procedure SetJoin(const Value: TStrokeJoin);
    function WidthStored: Boolean;
    function StyleStored: Boolean;
    function GetGradient: TGradient;
    procedure SetGradient(const Value: TGradient);
    function GetBitmap: TBrushBitmap;
    function GetKind: TBrushKind;
    function IsBitmapStored: Boolean;
    function IsGradientStored: Boolean;
    procedure SetBitmap(const Value: TBrushBitmap);
    procedure SetKind(const Value: TBrushKind);
  protected
    procedure DoChanged();
    procedure DoGradientChanged(Sender: TObject);
  public
    constructor Create(ADefaultStyle: TViewBorderStyle = TViewBorderStyle.None);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    property OnChanged: TNotifyEvent read FOnChanged write SetOnChanged;
    property Brush: TStrokeBrush read FBrush;
    property DefaultStyle: TViewBorderStyle read FDefaultStyle write FDefaultStyle;
  published
    property Color: TViewColor read FColor write SetColor;
    property Width: Single read GetWidth write SetWidth stored WidthStored;
    property Style: TViewBorderStyle read FStyle write SetStyle stored StyleStored;
    property Dash: TStrokeDash read GetDash write SetDash default TStrokeDash.Solid;
    property Cap: TStrokeCap read GetCap write SetCap default TStrokeCap.Flat;
    property Join: TStrokeJoin read GetJoin write SetJoin default TStrokeJoin.Miter;
    property Gradient: TGradient read GetGradient write SetGradient stored IsGradientStored;
    property Bitmap: TBrushBitmap read GetBitmap write SetBitmap stored IsBitmapStored;
    property Kind: TBrushKind read GetKind write SetKind default TBrushKind.Solid;
  end;

  TDrawableBorder = class(TDrawable)
  private
    FBorder: TViewBorder;
    procedure SetBorder(const Value: TViewBorder);
    function GetBorder: TViewBorder;
  protected
    function GetEmpty: Boolean; override;
    procedure CreateBorder(); virtual;
    procedure DoDrawed(Canvas: TCanvas; var R: TRectF; AState: TViewState); override;
  public
    constructor Create(View: IView; const ADefaultKind: TViewBrushKind = TViewBrushKind.None;
      const ADefaultColor: TAlphaColor = TAlphaColors.Null);
    destructor Destroy; override;
    procedure DrawBorder(Canvas: TCanvas; var R: TRectF; AState: TViewState);
    procedure Assign(Source: TPersistent); override;
    property _Border: TViewBorder read FBorder;
  published
    property Border: TViewBorder read GetBorder write SetBorder;
  end;

  TViewImageLink = class(TGlyphImageLink)
  public
    constructor Create(AOwner: TDrawableIcon); reintroduce;
    procedure Change; override;
  end;

  /// <summary>
  /// �ɻ���ˢ�����
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TDrawableBrush = class(TComponent, IGlyph, IInterfaceComponentReference)
  private
    FBrush: TBrush;
    FImageLink: TGlyphImageLink;
    FOnChanged: TNotifyEvent;
    function GetBrush: TBrush;
    function GetImages: TCustomImageList;
    function GetIsEmpty: Boolean;
    procedure SetBrush(const Value: TBrush);
    function GetImageIndexEx: TImageIndex;
    procedure SetImageIndexEx(const Value: TImageIndex);
  protected
    { IInterfaceComponentReference }
    function GetComponent: TComponent;
    {IGlyph}
    function GetImageIndex: TImageIndex;
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
    procedure ImagesChanged; virtual;
    function GetImageList: TBaseImageList; inline;
    procedure SetImageList(const Value: TBaseImageList);
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
  protected
    procedure CreateBrush(var Value: TBrush); virtual;
    procedure DoChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Draw(Canvas: TCanvas; const R: TRectF;
      const XRadius, YRadius: Single; const ACorners: TCorners;
      const AOpacity: Single = 1; const ACornerType: TCornerType = TCornerType.Round); virtual;
    property IsEmpty: Boolean read GetIsEmpty;
    property ImageIndex: TImageIndex read GetImageIndexEx write SetImageIndexEx;
  published
    property Images: TCustomImageList read GetImages write SetImages;
    property Brush: TBrush read GetBrush write SetBrush;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  /// <summary>
  /// �ɻ���ͼ��
  /// </summary>
  TDrawableIcon = class(TDrawableBase, IInterface, IGlyph, IInterfaceComponentReference)
  private
    FWidth: Integer;
    FHeight: Integer;
    FPadding: Integer;
    FPosition: TDrawablePosition;
    FImageLink: TGlyphImageLink;

    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetPadding(const Value: Integer);
    procedure SetPosition(const Value: TDrawablePosition);
    function GetImages: TCustomImageList;
  protected
    { IInterfaceComponentReference }
    function GetComponent: TComponent;
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    {IGlyph}
    function GetImageIndex: TImageIndex;
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
    procedure ImagesChanged; virtual;
    function GetImageList: TBaseImageList; inline;
    procedure SetImageList(const Value: TBaseImageList);
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
  protected
    function GetEmpty: Boolean; override;
    function GetStateImageIndex(): Integer; overload;
    function GetStateImageIndex(State: TViewState): Integer; overload; virtual;
  public
    constructor Create(View: IView; const ADefaultKind: TViewBrushKind = TViewBrushKind.None;
      const ADefaultColor: TAlphaColor = TAlphaColors.Null);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    /// <summary>
    /// ���ƣ�������ԭ��������
    /// </summary>
    procedure AdjustDraw(Canvas: TCanvas; var R: TRectF; ExecDraw: Boolean; AState: TViewState);

    procedure CreateBrush(var Value: TBrush; IsDefault: Boolean); override;
    procedure Draw(Canvas: TCanvas); override;
    procedure DrawStateTo(Canvas: TCanvas; const R: TRectF; AState: TViewState); override;
    procedure DrawImage(Canvas: TCanvas; Index: Integer; const R: TRectF); virtual;
  published
    property SizeWidth: Integer read FWidth write SetWidth default 16;
    property SizeHeight: Integer read FHeight write SetHeight default 16;
    property Padding: Integer read FPadding write SetPadding default 4;
    property Position: TDrawablePosition read FPosition write SetPosition default TDrawablePosition.Left;
    property Images: TCustomImageList read GetImages write SetImages;

    property XRadius;
    property YRadius;
    property Corners;
    property CornerType;
    property ItemDefault: TBrush index 0 read GetValue write SetValue;
    property ItemPressed: TBrush index 1 read GetValue write SetValue;
    property ItemFocused: TBrush index 2 read GetValue write SetValue;
    property ItemHovered: TBrush index 3 read GetValue write SetValue;
    property ItemSelected: TBrush index 4 read GetValue write SetValue;
    property ItemChecked: TBrush index 5 read GetValue write SetValue;
    property ItemEnabled: TBrush index 6 read GetValue write SetValue;
    property ItemActivated: TBrush index 7 read GetValue write SetValue;
  end;

  /// <summary>
  /// ��ɫ����
  /// </summary>
  TViewColor = class(TPersistent)
  private
    FOnChanged: TNotifyEvent;
    FDefault: TAlphaColor;
    FPressed: TAlphaColor;
    FFocused: TAlphaColor;
    FHovered: TAlphaColor;
    FSelected: TAlphaColor;
    FChecked: TAlphaColor;
    FEnabled: TAlphaColor;
    FActivated: TAlphaColor;
    FHintText: TAlphaColor;
    FColorStoreState: Cardinal;
    procedure SetDefault(const Value: TAlphaColor);
    procedure SetActivated(const Value: TAlphaColor);
    procedure SetChecked(const Value: TAlphaColor);
    procedure SetEnabled(const Value: TAlphaColor);
    procedure SetFocused(const Value: TAlphaColor);
    procedure SetHovered(const Value: TAlphaColor);
    procedure SetPressed(const Value: TAlphaColor);
    procedure SetSelected(const Value: TAlphaColor);
    function GetColorStoreState(const Index: Integer): Boolean;
    procedure SetColorStoreState(const Index: Integer; const Value: Boolean);
  private
    function ColorDefaultStored: Boolean;
    function ColorActivatedStored: Boolean;
    function ColorCheckedStored: Boolean;
    function ColorEnabledStored: Boolean;
    function ColorFocusedStored: Boolean;
    function ColorHoveredStored: Boolean;
    function ColorPressedStored: Boolean;
    function ColorSelectedStored: Boolean;
  protected
    procedure DoChange(Sender: TObject);
    function GetValue(const Index: Integer): TAlphaColor;
    procedure SetValue(const Index: Integer; const Value: TAlphaColor);
  public
    constructor Create(const ADefaultColor: TAlphaColor = TAlphaColorRec.Black);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    // ���ݵ�ǰ״̬��ȡ��ɫ�������ɫΪ Null �򷵻���һ�λ�ȡ������ɫ
    function GetStateColor(State: TViewState): TAlphaColor;

    function GetColor(State: TViewState): TAlphaColor;
    procedure SetColor(State: TViewState; const Value: TAlphaColor);

    property DefaultChange: Boolean index 1 read GetColorStoreState write SetColorStoreState;
    property PressedChange: Boolean index 2 read GetColorStoreState write SetColorStoreState;
    property FocusedChange: Boolean index 3 read GetColorStoreState write SetColorStoreState;
    property HoveredChange: Boolean index 4 read GetColorStoreState write SetColorStoreState;
    property SelectedChange: Boolean index 5 read GetColorStoreState write SetColorStoreState;
    property CheckedChange: Boolean index 6 read GetColorStoreState write SetColorStoreState;
    property EnabledChange: Boolean index 7 read GetColorStoreState write SetColorStoreState;
    property ActivatedChange: Boolean index 8 read GetColorStoreState write SetColorStoreState;

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property Default: TAlphaColor read FDefault write SetDefault stored ColorDefaultStored;
    property Pressed: TAlphaColor read FPressed write SetPressed stored ColorPressedStored;
    property Focused: TAlphaColor read FFocused write SetFocused stored ColorFocusedStored;
    property Hovered: TAlphaColor read FHovered write SetHovered stored ColorHoveredStored;
    property Selected: TAlphaColor read FSelected write SetSelected stored ColorSelectedStored;
    property Checked: TAlphaColor read FChecked write SetChecked stored ColorCheckedStored;
    property Enabled: TAlphaColor read FEnabled write SetEnabled stored ColorEnabledStored;
    property Activated: TAlphaColor read FActivated write SetActivated stored ColorActivatedStored;
  end;

  TTextColor = class(TViewColor)
  private
    procedure SetHintText(const Value: TAlphaColor);
    function GetHintText: TAlphaColor;
  published
    property HintText: TAlphaColor read GetHintText write SetHintText default TAlphaColorRec.Gray;
  end;

  /// <summary>
  /// ��ͼ��������
  /// </summary>
  TViewLayout = class(TPersistent)
  private
    [Weak] FView: IView;
    FOnChanged: TNotifyEvent;

    FToLeftOf: TControl;
    FToRightOf: TControl;
    FAbove: TControl;
    FBelow: TControl;
    FAlignBaseline: TControl;
    FAlignLeft: TControl;
    FAlignTop: TControl;
    FAlignRight: TControl;
    FAlignBottom: TControl;

    FAlignParentLeft: Boolean;
    FAlignParentTop: Boolean;
    FAlignParentRight: Boolean;
    FAlignParentBottom: Boolean;
    FCenterInParent: Boolean;
    FCenterHorizontal: Boolean;
    FCenterVertical: Boolean;

    procedure SetValue(var Dest: TControl; const Value: TControl); overload;
    procedure SetValue(var Dest: Boolean; const Value: Boolean); overload;
    procedure SetAbove(const Value: TControl);
    procedure SetAlignBaseline(const Value: TControl);
    procedure SetAlignBottom(const Value: TControl);
    procedure SetAlignLeft(const Value: TControl);
    procedure SetAlignRight(const Value: TControl);
    procedure SetAlignTop(const Value: TControl);
    procedure SetBelow(const Value: TControl);
    procedure SetToLeftOf(const Value: TControl);
    procedure SetToRightOf(const Value: TControl);
    procedure SetHeight(const Value: TViewSize);
    procedure SetWidth(const Value: TViewSize);
    procedure SetAlignParentBottom(const Value: Boolean);
    procedure SetAlignParentLeft(const Value: Boolean);
    procedure SetAlignParentRight(const Value: Boolean);
    procedure SetAlignParentTop(const Value: Boolean);
    procedure SetCenterHorizontal(const Value: Boolean);
    procedure SetCenterInParent(const Value: Boolean);
    procedure SetCenterVertical(const Value: Boolean);
    function GetHeight: TViewSize;
    function GetWidth: TViewSize;
  protected
    procedure DoChange(); virtual;
  public
    constructor Create(View: IView);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsEmpty: Boolean;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property ToLeftOf: TControl read FToLeftOf write SetToLeftOf;
    property ToRightOf: TControl read FToRightOf write SetToRightOf;
    property Above: TControl read FAbove write SetAbove;
    property Below: TControl read FBelow write SetBelow;
    property AlignBaseline: TControl read FAlignBaseline write SetAlignBaseline;
    property AlignLeft: TControl read FAlignLeft write SetAlignLeft;
    property AlignTop: TControl read FAlignTop write SetAlignTop;
    property AlignRight: TControl read FAlignRight write SetAlignRight;
    property AlignBottom: TControl read FAlignBottom write SetAlignBottom;
    property WidthSize: TViewSize read GetWidth write SetWidth default TViewSize.CustomSize;
    property HeightSize: TViewSize read GetHeight write SetHeight default TViewSize.CustomSize;
    property AlignParentLeft: Boolean read FAlignParentLeft write SetAlignParentLeft default False;
    property AlignParentTop: Boolean read FAlignParentTop write SetAlignParentTop default False;
    property AlignParentRight: Boolean read FAlignParentRight write SetAlignParentRight default False;
    property AlignParentBottom: Boolean read FAlignParentBottom write SetAlignParentBottom default False;
    property CenterInParent: Boolean read FCenterInParent write SetCenterInParent default False;
    property CenterHorizontal: Boolean read FCenterHorizontal write SetCenterHorizontal default False;
    property CenterVertical: Boolean read FCenterVertical write SetCenterVertical default False;
  end;

  /// <summary>
  /// ��������
  /// </summary>
  TLayoutGravity = (None, LeftTop, LeftBottom, RightTop, RightBottom,
    CenterVertical, CenterHorizontal, CenterHBottom, CenterVRight, Center);

  /// <summary>
  /// ��ʾ��ʽ
  /// </summary>
  TBadgeStyle = (EmptyText {�հ�}, NumberText {����ֵ (��ʾ����)},
    NewText {��ʾNew�ı�}, HotText {��ʾHot�ı�}, Icon {��ʾָ����ͼ��});

  /// <summary>
  /// �����ʾ�ӿ�
  /// </summary>
  IViewBadge = interface(IInterface)
    ['{493E5A10-0227-46AE-A17A-3B31D1B04D71}']
    function GetText: string;
    function GetIcon: TBrush;
    function GetValue: Integer;
    function GetMaxValue: Integer;
    function GetStyle: TBadgeStyle;
    procedure SetValue(const Value: Integer);
    procedure SetMaxValue(const Value: Integer);
    procedure SetStyle(const Value: TBadgeStyle);

    procedure Realign;
    procedure SetVisible(const Value: Boolean);

    property Value: Integer read GetValue write SetValue;
    property MaxValue: Integer read GetMaxValue write SetMaxValue;
    property Style: TBadgeStyle read GetStyle write SetStyle;
  end;

  /// <summary>
  /// ��ͼ�������Խӿ�
  /// </summary>
  IView = interface(IInterface)
    ['{9C2D9DB0-9D59-4A9D-BC47-53928194544E}']
    function GetBackground: TDrawable;
    function GetLayout: TViewLayout;
    function GetParentControl: TControl;
    function GetParentView: IViewGroup;
    function GetAdjustViewBounds: Boolean;
    function GetGravity: TLayoutGravity;
    function GetMaxHeight: Single;
    function GetMaxWidth: Single;
    function GetMinHeight: Single;
    function GetMinWidth: Single;
    function GetWeight: Single;
    function GetViewStates: TViewStates;
    function GetDrawState: TViewState;
    function GetHeightSize: TViewSize;
    function GetWidthSize: TViewSize;
    function GetOrientation: TOrientation;
    function GetComponent: TComponent;
    function GetComponentState: TComponentState;
    function GetInVisible: Boolean;
    function GetBadgeView: IViewBadge;

    function GetPosition: TPosition;
    function GetWidth: Single;
    function GetHeight: Single;
    function GetOpacity: Single;

    function IsAutoSize: Boolean;

    function LocalToAbsolute(const Point: TPointF): TPointF;

    procedure IncViewState(const State: TViewState);
    procedure DecViewState(const State: TViewState);

    procedure SetLayout(const Value: TViewLayout);
    procedure SetBackground(const Value: TDrawable);
    procedure SetWeight(const Value: Single);
    procedure SetGravity(const Value: TLayoutGravity);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetMaxHeight(const Value: Single);
    procedure SetMaxWidth(const Value: Single);
    procedure SetMinHeight(const Value: Single);
    procedure SetMinWidth(const Value: Single);
    procedure SetAdjustViewBounds(const Value: Boolean);
    procedure SetHeightSize(const Value: TViewSize);
    procedure SetWidthSize(const Value: TViewSize);
    procedure SetBadgeView(const Value: IViewBadge);

    property Layout: TViewLayout read GetLayout write SetLayout;
    property Background: TDrawable read GetBackground write SetBackground;
    property Weight: Single read GetWeight write SetWeight;
    property Gravity: TLayoutGravity read GetGravity write SetGravity;
    property Orientation: TOrientation read GetOrientation write SetOrientation;
    property MaxHeight: Single read GetMaxHeight write SetMaxHeight;
    property MaxWidth: Single read GetMaxWidth write SetMaxWidth;
    property MinHeight: Single read GetMinHeight write SetMinHeight;
    property MinWidth: Single read GetMinWidth write SetMinWidth;
    property AdjustViewBounds: Boolean read GetAdjustViewBounds write SetAdjustViewBounds;
    property HeightSize: TViewSize read GetHeightSize write SetHeightSize;
    property WidthSize: TViewSize read GetWidthSize write SetWidthSize;
    property BadgeView: IViewBadge read GetBadgeView write SetBadgeView;

    property Opacity: Single read GetOpacity;
    property Width: Single read GetWidth;
    property Height: Single read GetHeight;
    property Position: TPosition read GetPosition;
    property ParentControl: TControl read GetParentControl;
    property ParentView: IViewGroup read GetParentView;
    property InVisible: Boolean read GetInVisible;
  end;

  /// <summary>
  /// ��ͼ��ӿ�
  /// </summary>
  IViewGroup = interface(IView)
    ['{73A1B9E5-D4AF-4956-A15F-73B0B8EDADF9}']
    function AddView(View: TView): Integer;
    function RemoveView(View: TView): Integer;
    function GetAbsoluteInVisible: Boolean;
  end;

  TTextSettingsBase = class(TPersistent)
  private
    [Weak] FOwner: TControl;
    FOnChanged: TNotifyEvent;
    FOnTextChanged: TNotifyEvent;
    FOnLastFontChanged: TNotifyEvent;
    FLayout: TTextLayout;
    FPrefixStyle: TPrefixStyle;
    FGravity: TLayoutGravity;
    FTrimming: TTextTrimming;
    FText: string;
    FAutoSize: Boolean;
    FIsSizeChange: Boolean;
    FIsTextChange: Boolean;
    FIsEffectsChange: Boolean;
    FIsColorChange: Boolean;
    function GetGravity: TLayoutGravity;
    function GetWordWrap: Boolean;
    procedure SetFont(const Value: TFont);
    procedure SetGravity(const Value: TLayoutGravity);
    procedure SetPrefixStyle(const Value: TPrefixStyle);
    procedure SetTrimming(const Value: TTextTrimming);
    procedure SetWordWrap(const Value: Boolean);
    procedure SetText(const Value: string);
    procedure SetAutoSize(const Value: Boolean);
    function GetFillTextFlags: TFillTextFlags;
    function GetHorzAlign: TTextAlign;
    function GetVertAlign: TTextAlign;
    procedure SetHorzVertValue(const H, V: TTextAlign);
    procedure SetHorzAlign(const Value: TTextAlign);
    procedure SetVertAlign(const Value: TTextAlign);
    function GetTextLength: Integer;
    function GetFont: TFont;
  protected
    procedure DoChange; virtual;
    procedure DoTextChanged;
    procedure DoFontChanged(Sender: TObject);
    procedure DoColorChanged(Sender: TObject);
    function GetStateColor(const State: TViewState): TAlphaColor; virtual; abstract;
    function IsStoredGravity: Boolean; virtual;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure Change;

    function CalcTextObjectSize(const AText: string; const MaxWidth, SceneScale: Single;
      const Margins: TBounds; var Size: TSizeF): Boolean;

    function CalcTextWidth(const AText: string; SceneScale: Single): Single;
    function CalcTextHeight(const AText: string; SceneScale: Single): Single;

    procedure FillText(const Canvas: TCanvas; const ARect: TRectF; const AText: string; const AOpacity: Single;
      const Flags: TFillTextFlags; const ATextAlign: TTextAlign;
      const AVTextAlign: TTextAlign = TTextAlign.Center; State: TViewState = TViewState.None);

    procedure Draw(const Canvas: TCanvas; const R: TRectF;
        const Opacity: Single; State: TViewState); overload;
    procedure Draw(const Canvas: TCanvas; const AText: string; const R: TRectF;
        const Opacity: Single; State: TViewState); overload;
    procedure Draw(const Canvas: TCanvas; const AText: string; const R: TRectF;
        const Opacity: Single; State: TViewState; AGravity: TLayoutGravity); overload;

    property IsColorChange: Boolean read FIsColorChange;
    property IsSizeChange: Boolean read FIsSizeChange;
    property IsTextChange: Boolean read FIsTextChange;
    property IsEffectsChange: Boolean read FIsEffectsChange;

    property Text: string read FText write SetText;
    property TextLength: Integer read GetTextLength;
    property FillTextFlags: TFillTextFlags read GetFillTextFlags;

    property HorzAlign: TTextAlign read GetHorzAlign write SetHorzAlign;
    property VertAlign: TTextAlign read GetVertAlign write SetVertAlign;

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnTextChanged: TNotifyEvent read FOnTextChanged write FOnTextChanged;

    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property Font: TFont read GetFont write SetFont;
    property PrefixStyle: TPrefixStyle read FPrefixStyle write SetPrefixStyle default TPrefixStyle.NoPrefix;
    property Trimming: TTextTrimming read FTrimming write SetTrimming default TTextTrimming.None;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default False;
    property Gravity: TLayoutGravity read GetGravity write SetGravity stored IsStoredGravity;
  end;

  /// <summary>
  /// ��������
  /// </summary>
  TTextSettings = class(TTextSettingsBase)
  private
    FColor: TViewColor;
    FOpacity: Single;
    procedure SetColor(const Value: TViewColor);
    function IsStoreOpacity: Boolean;
    procedure SetOpacity(const Value: Single);
  protected
    function GetStateColor(const State: TViewState): TAlphaColor; override;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
  published
    property AutoSize;
    property Color: TViewColor read FColor write SetColor;
    property Font;
    property PrefixStyle;
    property Trimming;
    property WordWrap;
    property Gravity;
    property Opacity: Single read FOpacity write SetOpacity stored IsStoreOpacity;
  end;

  /// <summary>
  /// ��������������
  /// </summary>
  TScrollCalculations = class (TAniCalculations)
  private
    [Weak] FScrollView: TView;
  protected
    procedure DoChanged; override;
    procedure DoStart; override;
    procedure DoStop; override;
  public
    constructor Create(AOwner: TPersistent); override;
    property ScrollView: TView read FScrollView;
    property Shown;
    property MouseTarget;
    property MinTarget;
    property MaxTarget;
    property Target;
  end;

  TScrollBarHelper = class Helper for TScrollBar
  private
    function GetMaxD: Double;
    function GetMinD: Double;
    function GetValueD: Double;
    procedure SetMaxD(const Value: Double);
    procedure SetMinD(const Value: Double);
    procedure SetValueD(const Value: Double);
    function GetViewportSizeD: Double;
    procedure SetViewportSizeD(const Value: Double);
  public
    property MinD: Double read GetMinD write SetMinD;
    property MaxD: Double read GetMaxD write SetMaxD;
    property ValueD: Double read GetValueD write SetValueD;
    property ViewportSizeD: Double read GetViewportSizeD write SetViewportSizeD;
  end;

  TCustomTrackHelper = class Helper for TCustomTrack
  private
    function GetMaxD: Double;
    function GetMinD: Double;
    function GetValueD: Double;
    procedure SetMaxD(const Value: Double);
    procedure SetMinD(const Value: Double);
    procedure SetValueD(const Value: Double);
    function GetViewportSizeD: Double;
    procedure SetViewportSizeD(const Value: Double);
  public
    property MinD: Double read GetMinD write SetMinD;
    property MaxD: Double read GetMaxD write SetMaxD;
    property ValueD: Double read GetValueD write SetValueD;
    property ViewportSizeD: Double read GetViewportSizeD write SetViewportSizeD;
  end;

  TViewBase = class(TControl)
  protected
    function GetBackground: TDrawable; virtual;
    function GetViewBackground: TDrawable; virtual;
    function GetMaxHeight: Single; virtual;
    function GetMaxWidth: Single; virtual;
    function GetMinHeight: Single; virtual;
    function GetMinWidth: Single; virtual;
    function GetViewStates: TViewStates; virtual;
    procedure SetBackgroundBase(const Value: TDrawable); virtual; abstract;
    procedure SetMaxHeight(const Value: Single); virtual; abstract;
    procedure SetMaxWidth(const Value: Single); virtual; abstract;
    procedure SetMinHeight(const Value: Single); virtual; abstract;
    procedure SetMinWidth(const Value: Single); virtual; abstract;
    procedure SetViewStates(const Value: TViewStates); virtual; abstract;
  public
    property Background: TDrawable read GetViewBackground write SetBackgroundBase;
    property MinWidth: Single read GetMinWidth write SetMinWidth;
    property MinHeight: Single read GetMinHeight write SetMinHeight;
    property MaxWidth: Single read GetMaxWidth write SetMaxWidth;
    property MaxHeight: Single read GetMaxHeight write SetMaxHeight;
    property ViewState: TViewStates read GetViewStates write SetViewStates;
  end;

  /// <summary>
  /// ������ͼ
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TView = class(TViewBase, IView)
  const
    SmallChangeFraction = 5;
  private
    FInvaliding: Boolean;
    FRecalcInVisible: Boolean;
    FAbsoluteInVisible: Boolean;
    {$IFDEF MSWINDOWS}
    FCaptureDragForm: Boolean;
    {$ENDIF}
    function GetParentView: IViewGroup;
    function GetClickable: Boolean;
    procedure SetClickable(const Value: Boolean);
    function GetPaddings: string;
    procedure SetPaddings(const Value: string);
    function GetMargin: string;
    procedure SetMargin(const Value: string);
    procedure SetWeight(const Value: Single);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetAdjustViewBounds(const Value: Boolean);
    function GetLayout: TViewLayout;
    procedure SetLayout(const Value: TViewLayout);
    procedure SetHeightSize(const Value: TViewSize);
    procedure SetWidthSize(const Value: TViewSize);
    function GetAdjustViewBounds: Boolean;
    function GetGravity: TLayoutGravity;
    function GetWeight: Single;
    function GetOrientation: TOrientation;
    function GetComponent: TComponent;
    function GetComponentState: TComponentState;
    function GetOpacity: Single;
    function GetParentControl: TControl;
    function GetPosition: TPosition;
    function GetInVisible: Boolean;
    procedure SetInVisible(const Value: Boolean);
    procedure SetTempMaxHeight(const Value: Single);
    procedure SetTempMaxWidth(const Value: Single);
    function GetIsChecked: Boolean;
    procedure SetIsChecked(const Value: Boolean);
    function GetHeightSize: TViewSize;
    function GetWidthSize: TViewSize;
    function GetCaptureDragForm: Boolean;
    procedure SetCaptureDragForm(const Value: Boolean);
    function GetParentForm: TCustomForm;
  protected
    function GetViewRect: TRectF;
    function GetViewRectD: TRectD;
    function GetMaxHeight: Single; override;
    function GetMaxWidth: Single; override;
    function GetMinHeight: Single; override;
    function GetMinWidth: Single; override;
    function GetViewStates: TViewStates; override;
    function GetBackground: TDrawable; override;
    function GetViewBackground: TDrawable; override;
    function DoGetUpdateRect: TRectF; override;
    procedure SetMaxHeight(const Value: Single); override;
    procedure SetMaxWidth(const Value: Single); override;
    procedure SetMinHeight(const Value: Single); override;
    procedure SetMinWidth(const Value: Single); override;
    procedure SetViewStates(const Value: TViewStates); override;
    procedure SetBackgroundBase(const Value: TDrawable); override;
  protected
    FWeight: Single;
    FInVisible: Boolean;
    FGravity: TLayoutGravity;
    FOrientation: TOrientation;
    FBackground: TDrawable;
    FDrawing: Boolean;
    FViewState: TViewStates;
    FDrawState: TViewState;
    FMinWidth: Single;
    FMinHeight: Single;
    FMaxWidth: Single;
    FMaxHeight: Single;
    FWidthSize: TViewSize;
    FHeightSize: TViewSize;
    FSaveMaxWidth: Single;
    FSaveMaxHeight: Single;
    {$IFNDEF MSWINDOWS}
    FDownUpOffset: Single;
    {$ENDIF}
    FLayout: TViewLayout;
    [Weak] FBadgeView: IViewBadge;
    function IsDrawing: Boolean;
    function IsDesignerControl(Control: TControl): Boolean;
    function IsAutoSize: Boolean; virtual;
    function IsAdjustLayout: Boolean; virtual;
    function GetBadgeView: IViewBadge;
    procedure SetBadgeView(const Value: IViewBadge);
    function EmptyBackground(const V: TDrawable; const State: TViewState): Boolean;
    function CanRePaintBk(const View: IView; State: TViewState): Boolean; virtual;
    procedure IncViewState(const State: TViewState); virtual;
    procedure DecViewState(const State: TViewState); virtual;
    procedure IncChildState(State: TViewState); virtual;  // �������ӿؼ�����״̬
    procedure DecChildState(State: TViewState); virtual;  // �������ӿؼ�����״̬
    procedure DoActivate; override;
    procedure DoDeactivate; override;
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
    procedure EnabledChanged; override;
    procedure HitTestChanged; override;
    procedure VisibleChanged; override;
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
  protected
    FAdjustViewBounds: Boolean;
    procedure Paint; override;
    procedure AfterPaint; override;
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    procedure DoOrientation; virtual;
    procedure DoGravity; virtual;
    procedure DoWeight; virtual;
    procedure DoMaxSizeChange; virtual;
    procedure DoMinSizeChange; virtual;
    procedure DoInVisibleChange; virtual;
    procedure DoBackgroundChanged(Sender: TObject); virtual;
    procedure DoCheckedChange(); virtual;
    procedure DoEndUpdate; override;
    procedure DoMatrixChanged(Sender: TObject); override;
    procedure HandleSizeChanged; override;
    procedure Click; override;


    // �������������С��С
    procedure DoAdjustViewBounds(var ANewWidth, ANewHeight: Single); virtual;
    // ���ֱ仯��
    procedure DoLayoutChanged(Sender: TObject); virtual;
    // ��С�ı���
    procedure DoChangeSize(var ANewWidth, ANewHeight: Single); virtual;
    // ��ʼ�����С
    procedure DoRecalcSize(var AWidth, AHeight: Single); virtual;

    procedure DoMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
    procedure DoMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
    procedure PaintBackground; virtual;
    procedure SetGravity(const Value: TLayoutGravity); virtual;
    function AllowUseLayout(): Boolean; virtual;
    procedure ImagesChanged; virtual;
    function CreateBackground: TDrawable; virtual;
    function GetParentMaxWidth: Single;
    function GetParentMaxHeight: Single;
    function GetRealDrawState: TViewState; virtual;
    function GetDrawState: TViewState;
    function GetAbsoluteInVisible: Boolean; virtual;
    procedure RecalcInVisible; virtual;
  protected
    FScrollbar: TViewScroll;
    FDisableMouseWheel: Boolean;
    procedure SetScrollbar(const Value: TViewScroll); virtual;
    function GetSceneScale: Single;
    function GetAniCalculations: TScrollCalculations; virtual;
    procedure StartScrolling;
    procedure StopScrolling;
    procedure InternalAlign; virtual;
    procedure FreeScrollbar; virtual;
    procedure InitScrollbar; virtual;
    procedure SetDisableMouseWheel(const Value: Boolean);
    procedure DoSetScrollBarValue(Scroll: TScrollBar; const Value, ViewportSize: Double); virtual;
    procedure UpdateVScrollBar(const Value: Double; const ViewportSize: Double);
    procedure UpdateHScrollBar(const Value: Double; const ViewportSize: Double);
    function GetVScrollBar: TScrollBar; virtual;
    function GetHScrollBar: TScrollBar; virtual;
    function GetContentBounds: TRectD; virtual;
    function CanAnimation: Boolean; virtual;
    function GetScrollSmallChangeFraction: Single; virtual;
  protected
    {$IFDEF ANDROID}
    class procedure InitAudioManager();
    {$ENDIF}
  public
    /// <summary>
    /// ��������ʽ
    /// </summary>
    property ScrollBars: TViewScroll read FScrollbar write SetScrollbar default TViewScroll.None;
    /// <summary>
    /// ��ֹ������
    /// </summary>
    property DisableMouseWheel: Boolean read FDisableMouseWheel write SetDisableMouseWheel default False;
    /// <summary>
    /// ��������������
    /// </summary>
    property AniCalculations: TScrollCalculations read GetAniCalculations;

    property HScrollBar: TScrollBar read GetHScrollBar;
    property VScrollBar: TScrollBar read GetVScrollBar;
    property ContentBounds: TRectD read GetContentBounds;
    property AbsoluteInVisible: Boolean read GetAbsoluteInVisible;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function PointInObject(X, Y: Single): Boolean; override;
    procedure PlaySoundEffect(ASoundConstant: Integer);
    procedure PlayClickEffect(); virtual;

    procedure Invalidate;
    procedure DoResize;

    procedure SetBackground(const Value: TDrawable); overload;
    procedure SetBackground(const Value: TAlphaColor); overload;
    procedure SetBackground(const Value: TGradient); overload;
    procedure SetBackground(const Value: TBitmap); overload;
    procedure SetBackground(const Value: TBrushBitmap); overload;

    function IsPressed: Boolean;
    function IsHovered: Boolean;
    function IsActivated: Boolean;

    function FindStyleResource<T: TFmxObject>(const AStyleLookup: string; var AResource: T): Boolean; overload;
    function FindAndCloneStyleResource<T: TFmxObject>(const AStyleLookup: string; var AResource: T): Boolean;

    { ITriggerAnimation }
    procedure StartTriggerAnimation(const AInstance: TFmxObject; const ATrigger: string); override;
    procedure StartTriggerAnimationWait(const AInstance: TFmxObject; const ATrigger: string); override;

    /// <summary>
    /// ��ʼ�϶�����
    /// </summary>
    procedure StartWindowDrag;

    /// <summary>
    /// ��ȡ״̬���߶�
    /// </summary>
    class function GetStatusHeight: Single;
    /// <summary>
    /// ��ȡ�ײ�������߶�
    /// </summary>
    class function GetNavigationBarHeight: Single;

    { Rtti Function }
    class function GetRttiValue(Instance: TObject; const Name: string): TValue; overload;
    class function GetRttiValue<T>(Instance: TObject; const Name: string): T; overload;
    class function GetRttiObject(Instance: TObject; const Name: string): TObject;
    class procedure SetRttiValue(Instance: TObject; const Name: string; const Value: TValue); overload;
    class procedure SetRttiValue<T>(Instance: TObject; const Name: string; const Value: T); overload;

    property ParentView: IViewGroup read GetParentView;
    /// <summary>
    /// ����Ĳ��ַ�ʽ��Horizontal��ˮƽ���֣� Vertical����ֱ���֡�Ĭ��ΪHorizontal��
    /// </summary>
    property Orientation: TOrientation read GetOrientation write SetOrientation;
    /// <summary>
    /// �����ǰ��״̬
    /// </summary>
    property ViewState;
    /// <summary>
    /// �����ǰ�Ļ���״̬
    /// </summary>
    property DrawState: TViewState read FDrawState;
    /// <summary>
    /// ���������Ч���򣨷��ؼ�ȥPadding���ֵ��
    /// </summary>
    property ViewRect: TRectF read GetViewRect;
    property ViewRectD: TRectD read GetViewRectD;

    /// <summary>
    /// ��ʱ���߶�, ����Ϊ0ʱ���ָ�ԭʼ��MaxHeight
    /// </summary>
    property TempMaxHeight: Single read FMaxHeight write SetTempMaxHeight;
    /// <summary>
    /// ��ʱ���߶�, ����Ϊ0ʱ���ָ�ԭʼ��MaxWidth
    /// </summary>
    property TempMaxWidth: Single read FMaxWidth write SetTempMaxWidth;
    /// <summary>
    /// ��ʾ�����ͼ
    /// </summary>
    property BadgeView: IViewBadge read FBadgeView;
    /// <summary>
    /// ��ȡ����Form
    /// </summary>
    property ParentForm: TCustomForm read GetParentForm;
  published
    /// <summary>
    /// �������������Ķ��뷽ʽ��������Ϊ�ǲ������ʱ��Ч���ڲ��ֲ����������Ч����������ʹ�á�
    /// </summary>
    property Align;
    /// <summary>
    /// ����������е����źͶ�λ��ʽ��������Ϊ�ǲ������ʱ��Ч��
    /// </summary>
    property Anchors;
    /// <summary>
    /// �Ƿ��������MaxWidth, MaxHeight, MinWidth, MinHeight���������������С
    /// </summary>
    property AdjustViewBounds: Boolean read GetAdjustViewBounds write SetAdjustViewBounds default True;
    /// <summary>
    /// ��ͼ��������ͼ������һ��TDrawable���󣬿�ͨ�����ô����Ե������ʵ�ֲ�ͬ����ʾЧ�������TDrawable������˵����
    /// </summary>
    property Background;
    /// <summary>
    /// �Ƿ���Ӧ����¼���ͬHitTest����
    /// </summary>
    property Clickable: Boolean read GetClickable write SetClickable default False;
    /// <summary>
    /// �Ƿ���г���������������ͼ�����
    /// </summary>
    property ClipChildren default True;
    /// <summary>
    /// �Ƿ�ѡ��
    /// </summary>
    property Checked: Boolean read GetIsChecked write SetIsChecked default False;
    /// <summary>
    /// �Ƿ��������϶�������
    /// </summary>
    property CaptureDragForm: Boolean read GetCaptureDragForm write SetCaptureDragForm default False;
    /// <summary>
    /// �Ƿ�ִ�ж�������
    /// </summary>
    property EnableExecuteAction default False;
    /// <summary>
    /// ��Բ������ԡ���������TRelativeLayout��Բ���ʱ��Ч��Layout��һ��TViewLayout��������ο�TViewLayout����˵����
    /// </summary>
    property Layout: TViewLayout read GetLayout write SetLayout;
    /// <summary>
    /// ��������������״�С�����Զ�����Padding���ı߻���ͬ��ֵ��
    /// </summary>
    property Paddings: string read GetPaddings write SetPaddings stored False;
    /// <summary>
    /// ����ʱ������������ܵľ��롣��������һ���ַ�����ʽ�ĸ�����������һ������Margins���ı�Ϊ��ͬ�Ĵ�С��
    /// </summary>
    property Margin: string read GetMargin write SetMargin stored False;
    /// <summary>
    /// ����Ƿ���ӡ�Visible Ϊ True ʱ��Ч��InVisible Ϊ True ʱ��ֻ��λ�ò���ʾ����
    /// </summary>
    property InVisible: Boolean read FInVisible write SetInVisible default False;
    /// <summary>
    /// �����ȵ��ڷ�ʽ��CustomSize, ָ���Ĺ̶���С; WrapContent �����ݾ����� FillParent�����������
    /// </summary>
    property WidthSize: TViewSize read FWidthSize write SetWidthSize default TViewSize.CustomSize;
    /// <summary>
    /// ����߶ȵ��ڷ�ʽ��CustomSize, ָ���Ĺ̶���С; WrapContent �����ݾ����� FillParent�����������
    /// </summary>
    property HeightSize: TViewSize read FHeightSize write SetHeightSize default TViewSize.CustomSize;
    /// <summary>
    /// �������С��ȡ���AdjustViewBoundsΪTrueʱ��Ч��
    /// </summary>
    property MinWidth;
    /// <summary>
    /// �������С�߶ȡ���AdjustViewBoundsΪTrueʱ��Ч��
    /// </summary>
    property MinHeight;
    /// <summary>
    /// ���������ȡ���AdjustViewBoundsΪTrueʱ��Ч��
    /// </summary>
    property MaxWidth;
    /// <summary>
    /// ��������߶ȡ���AdjustViewBoundsΪTrueʱ��Ч��
    /// </summary>
    property MaxHeight;
    /// <summary>
    /// ���������Ϊ����ʱ���ڲ���������Ҳ�����������λ��������λ�á�
    ///    LeftTop, ���Ͻ�;
    ///    LeftBottom, ���½�;
    ///    RightTop, ���Ͻ�;
    ///    RightBottom, ���½�;
    ///    CenterVertical, ��ֱ���У��������ƶ���;
    ///    CenterHorizontal, ˮƽ���У��������ƶ���;
    ///    CenterHBottom, �ײ�ˮƽ����;
    ///    CenterVRight, ���Ҵ�ֱ����;
    ///    Center, ��ȫ����;
    /// </summary>
    property Gravity: TLayoutGravity read GetGravity write SetGravity;
    /// <summary>
    /// ��ͼ�����Բ��� TLinearLayout ʱ�����Ȼ�߶�����������ռ�Ĵ�С������
    /// ��Ϊ>0ʱ����������ᰴ�����Զ����������С��ֻ��������TLinearLayoutʱ��Ч��
    /// </summary>
    property Weight: Single read GetWeight write SetWeight;

    property Action;
    property Cursor;
    property ClipParent;
    property Enabled;
    property Locked;
    property Opacity;
    property RotationAngle;
    property RotationCenter;
    property Padding;
    property Margins;
    property PopupMenu;
    property Visible;
    property HitTest default False;
    property Width;
    property Height;
    property Scale;
    property Size;
    property Position;
    property TabOrder;
    property TabStop;
    { Events }
    property OnPainting;
    property OnPaint;
    property OnResize;
    { Drag and Drop events }
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    { Mouse events }
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

  /// <summary>
  /// ������ͼ��
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TViewGroup = class(TView, IViewGroup)
  private
  protected
    /// <summary>
    /// �Ƿ���Ҫ�Զ�������С
    /// </summary>
    function IsAdjustSize(View: IView; Align: TAlignLayout;
      AParentOrientation: TOrientation): Boolean;

    procedure DoAddObject(const AObject: TFmxObject); override;
    procedure DoLayoutChanged(Sender: TObject); override;
    procedure DoGravity(); override;
    procedure DoMaxSizeChange; override;
    procedure DoMinSizeChange; override;
    procedure Resize; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddView(View: TView): Integer;
    function RemoveView(View: TView): Integer;
  end;

  /// <summary>
  /// ���Բ���
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TLinearLayout = class(TViewGroup)
  private
  protected
    /// <summary>
    /// �������һ����Ҫ�Զ�������С�����
    /// <param name="AControl">�����Ҫ�Զ�������С�����</param>
    /// <param name="AdjustSize">����Զ�������С����Ŀ��ÿռ�</param>
    /// </summary>
    function AdjustAutoSizeControl(out AControl: TControl; out AdjustSize: Single): Boolean;

    function GetWeightSum(var FixSize: Single): Single;
    function GetLastWeightView(): TView;
    function IsUseWeight(): Boolean;
    procedure DoRealign; override;
    procedure DoOrientation; override;
    procedure DoRecalcSize(var AWidth, AHeight: Single); override;
  public
  published
    property Orientation;
  end;
  
  /// <summary>
  /// ��Բ���
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TRelativeLayout = class(TViewGroup)
  private
    FViewList: TList<TControl>;
    procedure DoAlignControl(const X, Y, W, H: Single);
  protected
    function GetXY(const StackList: TList<TControl>; const Control: TControl;
      var X, Y, W, H: Single): Integer;
    procedure DoRealign; override;
    procedure DoRecalcSize(var AWidth, AHeight: Single); override;
    procedure DoRemoveObject(const AObject: TFmxObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  /// <summary>
  /// ���Ӳ���ʱ����ģʽ
  /// </summary>
  TViewStretchMode = (None {��},
    SpacingWidth {�Զ�������࣬ʹ��������},
    ColumnWidth {�Զ�������ȣ�ʹ��������},
    SpacingWidthUniform {�Զ��������(ƽ�����)��ʹ��������});

  /// <summary>
  /// ���Ӳ���
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TGridsLayout = class(TViewGroup)
  private const
    CDefaultColumnWidth = 50;
    CDefaultColumnHeight = 50;
    CDefaultDividerColor = $FFF2E9E6;
  private
    FNumColumns: Integer;
    FColumnWidth: Single;
    FColumnHeight: Single;

    FSpacingBorder: Boolean;
    FVerticalSpacing: Single;
    FHorizontalSpacing: Single;

    FStretchMode: TViewStretchMode;
    FForceColumnSize: Boolean;

    FLastRH, FLastCW, FLastPW: Single;
    FLastColumns, FLastRows: Integer;
    FLastStretchMode: TViewStretchMode;

    FDividerBrush: TBrush;

    procedure SetNumColumns(const Value: Integer);
    function IsStoredColumnWidth: Boolean;
    procedure SetColumnWidth(const Value: Single);
    procedure SetHorizontalSpacing(const Value: Single);
    procedure SetVerticalSpacing(const Value: Single);
    procedure SetStretchMode(const Value: TViewStretchMode);
    function IsStoredColumnHeight: Boolean;
    procedure SetColumnHeight(const Value: Single);
    procedure SetDivider(const Value: TAlphaColor);
    function GetAbsoluteColumnsNum: Integer;
    function GetCount: Integer;
    function GetDivider: TAlphaColor;
    procedure SetForceColumnSize(const Value: Boolean);
    procedure SetSpacingBorder(const Value: Boolean);
  protected
    procedure DoRealign; override;
    procedure PaintBackground; override;
    procedure DrawDivider(Canvas: TCanvas);   // ���ָ���
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>
    /// ��������
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>
    /// ���Ե�����
    /// </summary>
    property AbsoluteColumnsNum: Integer read GetAbsoluteColumnsNum;
  published
    /// <summary>
    /// ����, <= 0 ʱΪ�Զ�
    /// </summary>
    property ColumnCount: Integer read FNumColumns write SetNumColumns default 0;
    /// <summary>
    /// �п��
    /// </summary>
    property ColumnWidth: Single read FColumnWidth write SetColumnWidth stored IsStoredColumnWidth;
    /// <summary>
    /// �и߶�
    /// </summary>
    property ColumnHeight: Single read FColumnHeight write SetColumnHeight stored IsStoredColumnHeight;
    /// <summary>
    /// �ָ�����ɫ
    /// </summary>
    property Divider: TAlphaColor read GetDivider write SetDivider default CDefaultDividerColor;
    /// <summary>
    /// ����֮��ļ��
    /// </summary>
    property SpacingHorizontal: Single read FHorizontalSpacing write SetHorizontalSpacing;
    /// <summary>
    /// ����֮��ļ��
    /// </summary>
    property SpacingVertical: Single read FVerticalSpacing write SetVerticalSpacing;
    /// <summary>
    /// ���ӱ߿�ʼ�� (Ϊ False ʱ�����������ıߵļ��Ϊ0)
    /// </summary>
    property SpacingBorder: Boolean read FSpacingBorder write SetSpacingBorder default True;
    /// <summary>
    /// �������п��С������ʽ
    /// </summary>
    property StretchMode: TViewStretchMode read FStretchMode write SetStretchMode default TViewStretchMode.None;
    /// <summary>
    /// ǿ��ʹ���д�С����ʱ���ټ��ÿ�����ӵĿ�ȸ߶��Ƿ���Ҫ�Զ���С
    /// </summary>
    property ForceColumnSize: Boolean read FForceColumnSize write SetForceColumnSize default False;
  end;

type
  /// <summary>
  /// �ര�ڹ��õ� ImageList
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TShareImageList = class(TImageList)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function GetShareImageList: TList<TShareImageList>;
  end;


// ������Ϣ
procedure ProcessMessages;
// ģ����
procedure SimulateClick(AControl: TControl; const x, y: single);
// �滻��͸����ɫ
procedure ReplaceOpaqueColor(ABmp: TBitmap; const Color: TAlphaColor);
// ��Ļ����
function GetScreenScale: single;

function ViewStateToString(const State: TViewStates): string;
function ComponentStateToString(const State: TComponentState): string;

var
  /// <summary>
  /// Accessory ͼ���б�
  /// </summary>
  FAccessoryImages: TViewAccessoryImageList;

implementation

uses
  UI.Ani;

resourcestring
  SInvViewValue = '��Ч����ͼ״ֵ̬: %d';
  SNotAllowSelf = '�������趨Ϊ�Լ�';
  SMustSameParent = '����ָ��һ���뵱ǰ���������ͼ�е�ͬ���ֵ����';
  SLocateFailed = '����ѭ������';
  SRefOutLimitMax = '������ò㼶��������ֵ: 256';
  SUnsupportPropertyType = '��֧�ֵ���������.';

var
  /// <summary>
  /// APP ״̬���߶� (Android ƽ̨��Ч)
  /// </summary>
  StatusHeight: Single = 0;
  /// <summary>
  /// APP �ײ�������߶� (Android ƽ̨��Ч)
  /// </summary>
  NavigationBarHeight: Single = 0;
  {$IFDEF ANDROID}
  FAudioManager: JAudioManager = nil;
  {$ENDIF}

var
  FShareImageList: TList<TShareImageList>;

function ComponentStateToString(const State: TComponentState): string;

  procedure Write(var P: PChar; const V: string);
  var
    PV, PM: PChar;
  begin
    PV := PChar(V);
    PM := PV + Length(V);
    while PV < PM do begin
      P^ := PV^;     
      Inc(P);
      Inc(PV); 
    end;
  end;
    
var
  P, P1: PChar;
begin
  SetLength(Result, 256);
  P := PChar(Result);
  P1 := P;   
  if csLoading in State then Write(P, 'csLoading,');
  if csReading in State then Write(P, 'csReading,');
  if csWriting in State then Write(P, 'csWriting,');
  if csDestroying in State then Write(P, 'csDestroying,');
  if csDesigning in State then Write(P, 'csDesigning,');
  if csAncestor in State then Write(P, 'csAncestor,');
  if csUpdating in State then Write(P, 'csUpdating,');
  if csFixups in State then Write(P, 'csFixups,');
  if csFreeNotification in State then Write(P, 'csFreeNotification,');
  if csInline in State then Write(P, 'csInline,');
  if csDesignInstance in State then Write(P, 'csDesignInstance,');
  if (P - P1) > 0 then
    SetLength(Result, P - P1 - 1)
  else
    Result := '';
end;

function ViewStateToString(const State: TViewStates): string;

  procedure Write(var P: PChar; const V: string);
  var
    PV, PM: PChar;
  begin
    PV := PChar(V);
    PM := PV + Length(V);
    while PV < PM do begin
      P^ := PV^;
      Inc(P);
      Inc(PV);
    end;
  end;

var
  P, P1: PChar;
begin
  SetLength(Result, 256);
  P := PChar(Result);
  P1 := P;
  if TViewState.Pressed in State then Write(P, 'Pressed,');
  if TViewState.Focused in State then Write(P, 'Focused,');
  if TViewState.Hovered in State then Write(P, 'Hovered,');
  if TViewState.Selected in State then Write(P, 'Selected,');
  if TViewState.Checked in State then Write(P, 'Checked,');
  if TViewState.Enabled in State then Write(P, 'Enabled,');
  if TViewState.Activated in State then Write(P, 'Activated,');
  if TViewState.Custom in State then Write(P, 'Custom,');
  if (P - P1) > 0 then
    SetLength(Result, P - P1 - 1)
  else
    Result := 'None';
end;

type TPrivateControl = class(TControl);

function GetBoundsFloat(const R: TBounds): string;
begin
  if Assigned(R) and (R.Left = R.Top) and (R.Left = R.Right) and (R.Left = R.Bottom) then
    Result := Format('%.1f', [R.Left])
  else Result := '';
end;

function GetFloatValue(const Value: string; var OutData: Single): Boolean;
var
  V: Single;
begin
  Result := False;
  if Length(Value) = 0 then Exit;
  V := StrToFloatDef(Value, 0);
  if (V = 0) and (Value <> '0') then Exit;
  OutData := V;
  Result := True;
end;

procedure CheckView(const List: TInterfaceList; const View: IView);

  procedure Check(const Control: TControl);
  var
    View: IView;
  begin
    if Supports(Control, IView, View) then
      CheckView(List, View);
  end;

var
  Layout: TViewLayout;
begin
  if Assigned(View) then begin
    if Assigned(List) and (List.Count > 0) then begin
      if List.Count > 256 then
        raise EViewError.Create(SRefOutLimitMax);
      if (List.IndexOf(View) >= 0) then // �ظ�����
        raise EViewError.Create(SLocateFailed);
    end;
    Layout := View.GetLayout;
        if not Assigned(Layout) then
      Exit;
    List.Add(View);
    try
      if Assigned(Layout.FAlignBaseline) then
        Check(Layout.FAlignBaseline);
      if Assigned(Layout.FAlignTop) then
        Check(Layout.FAlignTop);
      if Assigned(Layout.FAlignBottom) then
        Check(Layout.FAlignBottom);
      if Assigned(Layout.FAbove) then
        Check(Layout.FAbove);
      if Assigned(Layout.FBelow) then
        Check(Layout.FBelow);
      if Assigned(Layout.FAlignLeft) then
        Check(Layout.FAlignLeft);
      if Assigned(Layout.FAlignRight) then
        Check(Layout.FAlignRight);
      if Assigned(Layout.FToRightOf) then
        Check(Layout.FToRightOf);
      if Assigned(Layout.FToLeftOf) then
        Check(Layout.FToLeftOf);
    finally
      if List.Count > 0 then
        List.Delete(List.Count - 1);
    end;
  end;
end;

// �����������Ƿ������ѭ��������True��ʾ������
function CheckRecursionState(const Control: IView): Boolean;
var
  List: TInterfaceList;
begin
  if not Assigned(Control) then
    Result := True
  else begin
    List := TInterfaceList.Create;
    try
      CheckView(List, Control);
    finally
      List.Free;
    end;
    Result := True;
  end;
end;

{$IFDEF ANDROID}
procedure DoInitFrameStatusHeight();
var
  resourceId: Integer;
begin
  if TJBuild_VERSION.JavaClass.SDK_INT < 19 then
    Exit;
  try
    resourceId := {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
      .getResources().getIdentifier(
        StringToJString('status_bar_height'),
        StringToJString('dimen'),
        StringToJString('android'));
    if resourceId <> 0 then begin
      StatusHeight := {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
        .getResources().getDimensionPixelSize(resourceId);
      if StatusHeight > 0 then
        StatusHeight := StatusHeight / {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
          .getResources().getDisplayMetrics().scaledDensity;
    end else
      StatusHeight := 0;
  except
  end;
end;

// ��л Flying Wang
type
  JSystemPropertiesClass = interface(IJavaClass)
    ['{C14AB573-CC6F-4087-A1FB-047E92F8E718}']
    function get(name: JString): JString; cdecl;
  end;

  [JavaSignature('android/os/SystemProperties')]
  JSystemProperties = interface(IJavaInstance)
    ['{58A4A7BF-80D0-4FF8-9CF3-F94123C8EEB7}']
  end;
  TJSystemProperties = class(TJavaGenericImport<JSystemPropertiesClass, JSystemProperties>) end;

procedure DoInitNavigationBarHeight();
var
  resourceId: Integer;
  HasNavigationBar: Boolean;
  oStr: JString;
  AStr: string;
begin
  NavigationBarHeight := 0;
  if TJBuild_VERSION.JavaClass.SDK_INT < 21 then
    Exit;
  HasNavigationBar := False;
  try
    resourceId := {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
      .getResources.getIdentifier(
        StringToJString('config_showNavigationBar'),
        StringToJString('bool'),
        StringToJString('android'));
    if resourceId <> 0 then begin
      HasNavigationBar := TAndroidHelper.Context.getResources.getBoolean(resourceId);
      try
        // http://blog.csdn.net/lgaojiantong/article/details/42874529
        oStr := TJSystemProperties.JavaClass.get(StringToJString('qemu.hw.mainkeys'));
        if oStr = nil then Exit;
        AStr := JStringToString(oStr).Trim;
      except
        AStr := '';
      end;
      if AStr <> '' then begin
        if AStr = '0' then
          HasNavigationBar := True
        else if AStr = '1' then
          HasNavigationBar := False
        else begin
          if TryStrToBool(AStr, HasNavigationBar) then
            HasNavigationBar := not HasNavigationBar;
        end;
      end;
      if not HasNavigationBar then
        Exit;
      resourceId := {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
        .getResources.getIdentifier(
          StringToJString('navigation_bar_height'),
          StringToJString('dimen'),
          StringToJString('android'));
      if resourceId <> 0 then begin
        NavigationBarHeight := TAndroidHelper.Context.getResources.getDimensionPixelSize(resourceId);
        if NavigationBarHeight > 0 then
          NavigationBarHeight := NavigationBarHeight / {$IF CompilerVersion > 27}TAndroidHelper.Context{$ELSE}SharedActivityContext{$ENDIF}
            .getResources().getDisplayMetrics().scaledDensity;
      end;
    end;
  except
  end;
end;
{$ENDIF}

{ ���� KernowSoftwareFMX }
procedure ProcessMessages;
{$IFDEF IOS}
var
  TimeoutDate: NSDate;
begin
  TimeoutDate := TNSDate.Wrap(TNSDate.OCClass.dateWithTimeIntervalSinceNow(0.0));
  TNSRunLoop.Wrap(TNSRunLoop.OCClass.currentRunLoop).runMode(NSDefaultRunLoopMode, TimeoutDate);
end;
{$ELSE}
begin
  // FMX can occasionally raise an exception.
  try
    Application.ProcessMessages;
  except end;
end;
{$ENDIF}

{ ���� KernowSoftwareFMX }
procedure ReplaceOpaqueColor(ABmp: TBitmap; const Color: TAlphaColor);
var
  x, y: Integer;
  AMap: TBitmapData;
  PixelColor: TAlphaColor;
  //PixelWhiteColor: TAlphaColor;
  C: PAlphaColorRec;
begin
  if (Assigned(ABmp)) then begin
    if ABmp.Map(TMapAccess.ReadWrite, AMap) then
    try
      AlphaColorToPixel(Color   , @PixelColor, AMap.PixelFormat);
      //AlphaColorToPixel(claWhite, @PixelWhiteColor, AMap.PixelFormat);
      for y := 0 to ABmp.Height - 1 do begin
        for x := 0 to ABmp.Width - 1 do begin
          C := @PAlphaColorArray(AMap.Data)[y * (AMap.Pitch div 4) + x];
          if (C^.Color <> claWhite) and (C^.A > 0) then begin
            TAlphaColorRec(PixelColor).A := C^.A;
            C^.Color := PremultiplyAlpha(PixelColor);
          end;
            //C^.Color := PremultiplyAlpha(MakeColor(PixelColor, C^.A / $FF));
        end;
      end;
    finally
      ABmp.Unmap(AMap);
    end;
  end;
end;

procedure SimulateClick(AControl: TControl; const x, y: single);
var
  AForm: TCommonCustomForm;
  AFormPoint: TPointF;
begin
  AForm := nil;
  if (AControl.Root is TCustomForm) then
    AForm := (AControl.Root as TCustomForm);
  if AForm <> nil then
  begin
    AFormPoint := AControl.LocalToAbsolute(PointF(X,Y));
    AForm.MouseDown(TMouseButton.mbLeft, [], AFormPoint.X, AFormPoint.Y);
    AForm.MouseUp(TMouseButton.mbLeft, [], AFormPoint.X, AFormPoint.Y);
  end;
end;

var
  AScreenScale: Single;

function GetScreenScale: single;
var
  Service: IFMXScreenService;
begin
  if AScreenScale > 0 then begin
    Result := AScreenScale;
    Exit;
  end;
  Service := IFMXScreenService(TPlatformServices.Current.GetPlatformService(IFMXScreenService));
  Result := Service.GetScreenScale;
  {$IFDEF IOS}
  if Result < 2 then
    Result := 2;
  {$ENDIF}
  AScreenScale := Result;
end;

{ TDrawableBase }

procedure TDrawableBase.Assign(Source: TPersistent);

  procedure AssignItem(State: TViewState; const Src: TDrawableBase);
  var V: TBrush;
  begin
    Src.GetStateBrush(State, V);
    if Assigned(V) then
      GetBrush(State, True).Assign(V)
    else begin
      GetStateBrush(State, V);
      FreeAndNil(V);
    end;
  end;

var
  SaveChange: TNotifyEvent;
  Src: TDrawable;
begin
  if Source is TDrawableBase then begin
    SaveChange := FOnChanged;
    FOnChanged := nil;
    Src := TDrawable(Source);
    FCornerType := Src.FCornerType;
    FCorners := Src.Corners;
    AssignItem(TViewState.None, Src);
    AssignItem(TViewState.Pressed, Src);
    AssignItem(TViewState.Focused, Src);
    AssignItem(TViewState.Hovered, Src);
    AssignItem(TViewState.Selected, Src);
    AssignItem(TViewState.Checked, Src);
    AssignItem(TViewState.Enabled, Src);
    AssignItem(TViewState.Activated, Src);
    FOnChanged := SaveChange;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end else
    inherited;
end;

function TDrawableBase.BrushIsEmpty(V: TBrush): Boolean;
begin
  if (not Assigned(V)) or (V.Kind = TBrushKind.None) or
    ((V.Color and $FF000000 = 0) and (V.Kind = TBrushKind.Solid)) or
    ((Ord(V.Kind) = Ord(TViewBrushKind.AccessoryBitmap)) and (TViewBrushBase(V).FAccessoryType = TViewAccessoryType.None))
  then begin
    if (V is TViewImagesBrush) and (TViewImagesBrush(V).FImageIndex >= 0) then
      Result := False
    else
      Result := True
  end else
    Result := False;
end;

procedure TDrawableBase.Change;
begin
  DoChange(Self);
end;

constructor TDrawableBase.Create(View: IView; const ADefaultKind: TViewBrushKind;
  const ADefaultColor: TAlphaColor);
begin
  FView := View;
  FDefaultColor := ADefaultColor;
  FDefaultKind := ADefaultKind;
  FCorners := AllCorners;
  FCornerType := TCornerType.Round;

  if Assigned(FView) and (csDesigning in FView.GetComponentState) then begin
    CreateBrush(FDefault, True);
    CreateBrush(FPressed, False);
    CreateBrush(FFocused, False);
    CreateBrush(FHovered, False);
    CreateBrush(FSelected, False);
    CreateBrush(FChecked, False);
    CreateBrush(FEnabled, False);
    CreateBrush(FActivated, False);
    FIsEmpty := GetEmpty;
  end else begin
    FIsEmpty := True;
    if (FDefaultKind = TViewBrushKind.Solid) and (FDefaultColor <> TAlphaColorRec.Null) then
      CreateBrush(FDefault, True);
  end;
  InitDrawable;
end;

procedure TDrawableBase.CreateBrush(var Value: TBrush; IsDefault: Boolean);
begin
  if Assigned(Value) then
    FreeAndNil(Value);
  if IsDefault then
    Value := TViewBrush.Create(FDefaultKind, FDefaultColor)
  else
    Value := TViewBrush.Create(TViewBrushKind.None, TAlphaColorRec.Null);
  Value.OnChanged := DoChange;
end;

function TDrawableBase.CreateBrush: TBrush;
begin
  CreateBrush(Result, False);
end;

destructor TDrawableBase.Destroy;
begin
  FOnChanged := nil;
  FreeAndNil(FDefault);
  FreeAndNil(FPressed);
  FreeAndNil(FFocused);
  FreeAndNil(FHovered);
  FreeAndNil(FSelected);
  FreeAndNil(FChecked);
  FreeAndNil(FEnabled);
  FreeAndNil(FActivated);
  inherited;
end;

procedure TDrawableBase.DoChange(Sender: TObject);
begin
  FIsEmpty := GetEmpty;
  if Assigned(FOnChanged) then
    FOnChanged(Sender);
end;

procedure TDrawableBase.DoDrawed(Canvas: TCanvas; var R: TRectF; AState: TViewState);
begin
end;

function TDrawableBase.GetValue(const Index: Integer): TBrush;
begin
  Result := GetBrush(TViewState(Index), not (csLoading in FView.GetComponentState));
end;

procedure TDrawableBase.InitDrawable;
begin
end;

function TDrawableBase.IsStoredCorners: Boolean;
begin
  Result := FCorners <> AllCorners;
end;

function TDrawableBase.GetBrush(const State: TViewState; AutoCreate: Boolean): TBrush;
begin
  GetStateBrush(State, Result);
  if (Result = nil) and
    (AutoCreate or (csLoading in FView.GetComponentState)) then
  begin
    CreateBrush(Result, State = TViewState.None);
    SetStateBrush(State, Result);
  end;
end;

function TDrawableBase.GetDrawRect(const ALeft, ATop, ARight, ABottom: Single): TRectF;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

function TDrawableBase.GetEmpty: Boolean;
begin
  Result := ((FDefault = nil) or (FDefault.Kind = TBrushKind.None)) and
    ((FPressed = nil) or (FPressed.Kind = TBrushKind.None)) and
    ((FFocused = nil) or (FFocused.Kind = TBrushKind.None)) and
    ((FHovered = nil) or (FHovered.Kind = TBrushKind.None)) and
    ((FSelected = nil) or (FSelected.Kind = TBrushKind.None)) and
    ((FChecked = nil) or (FChecked.Kind = TBrushKind.None)) and
    ((FEnabled = nil) or (FEnabled.Kind = TBrushKind.None)) and
    ((FActivated = nil) or (FActivated.Kind = TBrushKind.None));
end;

function TDrawableBase.GetStateBrush(const State: TViewState): TBrush;
begin
  GetStateBrush(State, Result);
end;

procedure TDrawableBase.GetStateBrush(const State: TViewState; var V: TBrush);
begin
  case State of
    TViewState.None: V := FDefault;
    TViewState.Pressed: V := FPressed;
    TViewState.Focused: V := FFocused;
    TViewState.Hovered: V := FHovered;
    TViewState.Selected: V := FSelected;
    TViewState.Checked: V := FChecked;
    TViewState.Enabled: V := FEnabled;
    TViewState.Activated: V := FActivated;
  else
    raise EDrawableError.Create(Format(SInvViewValue, [Integer(State)]));
  end;
end;

function TDrawableBase.GetStateImagesItem(AState: TViewState): TBrush;
begin
  GetStateBrush(AState, Result);
  if Result <> FDefault then begin
    if BrushIsEmpty(Result) then
    begin
      if (AState = TViewState.Pressed) then begin
        Result := FFocused;
        if BrushIsEmpty(Result) then
          Result := FDefault
      end else
        Result := FDefault;
    end;
  end;
  if BrushIsEmpty(Result) then
    Result := nil;
end;

function TDrawableBase.GetStateItem(AState: TViewState): TBrush;
begin
  GetStateBrush(AState, Result);
  if Result <> FDefault then begin
    if BrushIsEmpty(Result) then
    begin
      if (AState = TViewState.Pressed) then begin
        Result := FFocused;
        if BrushIsEmpty(Result) then
          Result := FDefault
      end else
        Result := FDefault;
    end;
  end;
  if BrushIsEmpty(Result) then
    Result := nil;
end;

procedure TDrawableBase.Draw(Canvas: TCanvas);
var
  V: TBrush;
  R: TRectF;
  AState: TViewState;
begin
  if FIsEmpty or (not Assigned(FView)) then Exit;
  if FView.InVisible or (csDestroying in FView.GetComponentState) then Exit;
  AState := FView.GetDrawState;
  R := GetDrawRect(0, 0, FView.GetWidth, FView.GetHeight);
  V := GetStateItem(AState);
  if V <> nil then
    FillRect(Canvas, R, FXRadius, FYRadius, FCorners, FView.GetOpacity, V, FCornerType);
  DoDrawed(Canvas, R, AState);
end;

procedure TDrawableBase.DrawBrushTo(Canvas: TCanvas; ABrush: TBrush;
  const R: TRectF);
begin
  if ABrush <> nil then
    FillRect(Canvas, R, FXRadius, FYRadius, FCorners, FView.GetOpacity, ABrush, FCornerType);
end;

procedure TDrawableBase.DrawStateTo(Canvas: TCanvas; const R: TRectF;
  AState: TViewState);
var
  V: TBrush;
  VR: TRectF;
begin
  if FIsEmpty or (not Assigned(FView)) then Exit;
  if FView.InVisible or (csDestroying in FView.GetComponentState) then Exit;
  V := GetStateItem(AState);
  VR := GetDrawRect(R.Left, R.Top, R.Right, R.Bottom);
  if V <> nil then
    FillRect(Canvas, VR, FXRadius, FYRadius, FCorners, FView.GetOpacity, V, FCornerType);
  DoDrawed(Canvas, VR, AState);
end;

procedure TDrawableBase.DrawTo(Canvas: TCanvas; const R: TRectF);
begin
  if FIsEmpty or (not Assigned(FView)) then Exit;
  DrawStateTo(Canvas, R, FView.GetDrawState);
end;

procedure TDrawableBase.FillArc(Canvas: TCanvas; const Center, Radius: TPointF;
  const StartAngle, SweepAngle, AOpacity: Single; const ABrush: TBrush);
begin
  Canvas.FillArc(Center, Radius, StartAngle, SweepAngle, AOpacity, ABrush);
end;

procedure TDrawableBase.FillRect(Canvas: TCanvas; const ARect: TRectF;
  const XRadius, YRadius: Single; const ACorners: TCorners;
  const AOpacity: Single; const ABrush: TBrush;
  const ACornerType: TCornerType = TCornerType.Round);
var
  Bmp: TBitmap;
begin
  if (Ord(ABrush.Kind) = Ord(TViewBrushKind.Patch9Bitmap)) and (ABrush is TViewBrush) then begin
    FillRect9Patch(Canvas, ARect, XRadius, YRadius, ACorners, AOpacity, TViewBrush(ABrush), ACornerType);
  end else begin
    if Ord(ABrush.Kind) = Ord(TViewBrushKind.AccessoryBitmap) then begin
      Bmp := TViewBrushBase(ABrush).FAccessoryBmp;
      if Assigned(Bmp) then
        Canvas.DrawBitmap(Bmp, RectF(0, 0, Bmp.Width, Bmp.Height), ARect, AOpacity, True);
    end else
      Canvas.FillRect(ARect, XRadius, YRadius, ACorners, AOpacity, ABrush, ACornerType);
  end;
end;

class procedure TDrawableBase.FillRect9Patch(Canvas: TCanvas; const ARect: TRectF;
  const XRadius, YRadius: Single; const ACorners: TCorners;
  const AOpacity: Single; const ABrush: TViewBrush;
  const ACornerType: TCornerType);
var
  Bmp: TPatch9Bitmap;
  AOnChanged: TNotifyEvent;
  AO: Single;
  BL, BT, BR, BB: Single;
  BW, BH: Single;
begin
  if (ABrush.Bitmap = nil) or (ABrush.Bitmap.Bitmap = nil) or
    ABrush.Bitmap.Bitmap.IsEmpty then
    Exit;

  Bmp := TPatch9Bitmap(ABrush.Bitmap);
  AOnChanged := ABrush.OnChanged;
  ABrush.OnChanged := nil;
  ABrush.Kind := TViewBrushKind.Bitmap;

  if Bmp.FRemoveBlackLine then begin
    {$IFNDEF MSWINDOWS}
    // �ƶ�ƽ̨��ʹ��PPI�����1��dp��ռ�õ�����
    // �о�ֱ����Ϊ2Ч������
    AO := 2; //1 * GetPPI(Self.FView as TFmxObject) / 160;
    //if AO < 0 then AO := 1;
    {$ELSE}
    AO := 1;
    {$ENDIF}
  end else
    AO := 0;

  if (Bmp.FBounds.Left = 0) and (Bmp.FBounds.Top = 0) and (Bmp.FBounds.Right = 0) and (Bmp.FBounds.Bottom = 0) then begin
    if AO = 0 then
      Canvas.FillRect(ARect, XRadius, YRadius, ACorners, AOpacity, ABrush, ACornerType)
    else
      Canvas.DrawBitmap(Bmp.Bitmap, RectF(AO, AO, Bmp.Bitmap.Width - AO, Bmp.Bitmap.Height - AO),
        ARect, AOpacity);
  end else begin
    // �Ź����ͼ
    BW := Bmp.Bitmap.Width;
    BH := Bmp.Bitmap.Height;

    BL := Bmp.FBounds.Left;
    BT := Bmp.FBounds.Top;
    BR := Bmp.FBounds.Right;
    BB := Bmp.FBounds.Bottom;

    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(AO, AO, BL + AO, BT + AO),
      RectF(ARect.Left, ARect.Top, ARect.Left + BL, ARect.Top + BT),
      AOpacity);
    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BL + AO, AO, BW - BR - AO, BT + AO),
      RectF(ARect.Left + BL, ARect.Top, ARect.Right - BR, ARect.Top + BT),
      AOpacity);
    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BW - BR - AO, AO, BW - AO, BT + AO),
      RectF(ARect.Right - BR, ARect.Top, ARect.Right, ARect.Top + BT),
      AOpacity);

    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(AO, BT + AO, BL + AO, BH - BB - AO),
      RectF(ARect.Left, ARect.Top + BT, ARect.Left + BL, ARect.Bottom - BB),
      AOpacity);
    // �м�
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BL + AO, BT + AO, BW - BR - AO, BH - BB - AO),
      RectF(ARect.Left + BL, ARect.Top + BT, ARect.Right - BR, ARect.Bottom - BB),
      AOpacity);
    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BW - BR - AO, BT + AO, BW - AO, BH - BB - AO),
      RectF(ARect.Right - BR, ARect.Top + BT, ARect.Right, ARect.Bottom - BB),
      AOpacity);

    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(AO, BH - BB - AO, BL + AO, BH - AO),
      RectF(ARect.Left, ARect.Bottom - BB, ARect.Left + BL, ARect.Bottom),
      AOpacity);
    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BL + AO, BH - BB - AO, BW - BR - AO, BH - AO),
      RectF(ARect.Left + BL, ARect.Bottom - BB, ARect.Right - BR, ARect.Bottom),
      AOpacity);
    // ����
    Canvas.DrawBitmap(Bmp.Bitmap,
      RectF(BW - BR - AO, BH - BB - AO, BW - AO, BH - AO),
      RectF(ARect.Right - BR, ARect.Bottom - BB, ARect.Right, ARect.Bottom),
      AOpacity);
  end;

  ABrush.Kind := TViewBrushKind.Patch9Bitmap;
  ABrush.OnChanged := AOnChanged;
end;

procedure TDrawableBase.SetDrawable(const Value: TDrawableBase);
begin
  Assign(Value);
end;

procedure TDrawableBase.SetColor(State: TViewState; const Value: TAlphaColor);
var V: TBrush;
begin
  V := GetBrush(State, True);
  V.Kind := TBrushKind.Solid;
  V.Color := Value;
end;

procedure TDrawableBase.SetCorners(const Value: TCorners);
begin
  if FCorners <> Value then begin
    FCorners := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableBase.SetCornerType(const Value: TCornerType);
begin
  if FCornerType <> Value then begin
    FCornerType := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableBase.SetGradient(State: TViewState; const Value: TGradient);
var V: TBrush;
begin
  V := GetBrush(State, True);
  V.Gradient.Assign(Value);
  V.Kind := TBrushKind.Gradient;
end;

procedure TDrawableBase.SetRadius(const X, Y: Single);
begin
  FYRadius := Y;
  FXRadius := X;
  DoChange(Self);
end;

procedure TDrawableBase.SetBitmap(State: TViewState; const Value: TBrushBitmap);
var V: TBrush;
begin
  V := GetBrush(State, True);
  V.Bitmap.Assign(Value);
  V.Kind := TBrushKind.Bitmap;
end;

procedure TDrawableBase.SetBrush(State: TViewState;
  const Value: TDrawableBrush);
var V: TBrush;
begin
  if not Assigned(Value) then Exit;
  V := GetBrush(State, True);
  if (Self is TDrawableIcon) and (Value.ImageIndex >= 0) then
    TDrawableIcon(Self).Images := Value.Images;
  V.Assign(Value.Brush);
end;

procedure TDrawableBase.SetBrush(State: TViewState; const Value: TBrush);
begin
  GetBrush(State, True).Assign(Value);
end;

procedure TDrawableBase.SetBitmap(State: TViewState; const Value: TBitmap);
var V: TBrush;
begin
  V := GetBrush(State, True);
  V.Bitmap.Bitmap.Assign(Value);
  V.Kind := TBrushKind.Bitmap;
end;

procedure TDrawableBase.SetStateBrush(const State: TViewState; const V: TBrush);
begin
  case State of
    TViewState.None: FDefault := V;
    TViewState.Pressed: FPressed := V;
    TViewState.Focused: FFocused := V;
    TViewState.Hovered: FHovered := V;
    TViewState.Selected: FSelected := V;
    TViewState.Checked: FChecked := V;
    TViewState.Enabled: FEnabled := V;
    TViewState.Activated: FActivated := V;
  end;
end;

procedure TDrawableBase.SetValue(const Index: Integer; const Value: TBrush);
begin
  SetBrush(TViewState(Index), Value);
end;

procedure TDrawableBase.SetXRadius(const Value: Single);
begin
  if FXRadius <> Value then begin
    FXRadius := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableBase.SetYRadius(const Value: Single);
begin
  if FYRadius <> Value then begin
    FYRadius := Value;
    DoChange(Self);
  end;
end;

{ TDrawable }

procedure TDrawable.Assign(Source: TPersistent);
var
  LastOnChange: TNotifyEvent;
begin
  if Source is TDrawable then begin
    LastOnChange := FPadding.OnChange;
    FPadding.OnChange := nil;
    FPadding.Assign(TDrawable(Source).FPadding);
    FPadding.OnChange := LastOnChange;
  end;
  inherited Assign(Source);
end;

constructor TDrawable.Create(View: IView; const ADefaultKind: TViewBrushKind;
  const ADefaultColor: TAlphaColor);
begin
  FPadding := TBounds.Create(TRectF.Empty);
  FPadding.OnChange := DoChange;
  inherited Create(View, ADefaultKind, ADefaultColor);
end;

destructor TDrawable.Destroy;
begin
  FreeAndNil(FPadding);
  inherited Destroy;
end;

function TDrawable.GetDrawRect(const ALeft, ATop, ARight, ABottom: Single): TRectF;
begin
  Result.Left := ALeft + FPadding.Left;
  Result.Top := ATop + FPadding.Top;
  Result.Right := ARight - FPadding.Right;
  Result.Bottom := ABottom - FPadding.Bottom;
end;

function TDrawable.GetPaddings: string;
begin
  Result := GetBoundsFloat(FPadding);
end;

function TDrawable.GetValue(const Index: Integer): TViewBrush;
begin
  Result := inherited GetBrush(TViewState(Index),
    not (csLoading in FView.GetComponentState)) as TViewBrush;
end;

procedure TDrawable.SetPadding(const Value: TBounds);
begin
  FPadding.Assign(Value);
end;

procedure TDrawable.SetPaddings(const Value: string);
var
  V: Single;
begin
  if Assigned(Padding) and GetFloatValue(Value, V) then
    Padding.Rect := RectF(V, V, V, V);
end;

procedure TDrawable.SetValue(const Index: Integer; const Value: TViewBrush);
begin
  inherited SetValue(Index, Value);
end;

{ TDrawableIcon }

procedure TDrawableIcon.AdjustDraw(Canvas: TCanvas; var R: TRectF; ExecDraw: Boolean;
  AState: TViewState);
var
  DR: TRectF;
  SW, SH: Single;
begin
  SW := R.Right - R.Left;
  SH := R.Bottom - R.Top;
  case FPosition of
    TDrawablePosition.Left:
      begin
        if ExecDraw then begin        
          DR.Left := R.Left;
          DR.Top := R.Top + (SH - FHeight) / 2;
          DR.Right := DR.Left + FWidth;
          DR.Bottom := DR.Top + FHeight;  
          DrawStateTo(Canvas, DR, AState);
        end;
        R.Left := R.Left + FWidth + FPadding;
      end;
    TDrawablePosition.Right: 
      begin
        if ExecDraw then begin
          DR.Left := R.Right - FWidth;
          DR.Top := R.Top + (SH - FHeight) / 2;
          DR.Right := R.Right;
          DR.Bottom := DR.Top + FHeight;
          DrawStateTo(Canvas, DR, AState);
        end;
        R.Right := R.Right - FWidth - FPadding;
      end;
    TDrawablePosition.Top: 
      begin
        if ExecDraw then begin
          DR.Left := R.Left + (SW - FWidth) / 2;
          DR.Top := R.Top;
          DR.Right := DR.Left + FWidth;
          DR.Bottom := DR.Top + FHeight;
          DrawStateTo(Canvas, DR, AState);
        end;
        R.Top := R.Top + FHeight + FPadding;
      end;
    TDrawablePosition.Bottom:
      begin
        if ExecDraw then begin
          DR.Left := R.Left + (SW - FWidth) / 2;
          DR.Top := R.Bottom - FHeight;
          DR.Right := DR.Left + FWidth;
          DR.Bottom := R.Bottom;
          DrawStateTo(Canvas, DR, AState);
        end;
        R.Bottom := R.Bottom - FHeight - FPadding;
      end;
    TDrawablePosition.Center:
      begin
        if ExecDraw then begin
          DR.Left := R.Left + (SW - FWidth) / 2;
          DR.Top := R.Top + (SH - FHeight) / 2;
          DR.Right := DR.Left + FWidth;
          DR.Bottom := DR.Top + FHeight;
          DrawStateTo(Canvas, DR, AState);
        end;
      end;
  end;
end;

procedure TDrawableIcon.Assign(Source: TPersistent);
begin
  if Source is TDrawableIcon then begin
    FWidth := TDrawableIcon(Source).FWidth;
    FHeight := TDrawableIcon(Source).FHeight;
    FPadding := TDrawableIcon(Source).FPadding;
    FPosition := TDrawableIcon(Source).FPosition;
  end;
  inherited Assign(Source);
end;

constructor TDrawableIcon.Create(View: IView; const ADefaultKind: TViewBrushKind;
  const ADefaultColor: TAlphaColor);
begin
  FView := View;
  FImageLink := TViewImageLink.Create(Self);
  FImageLink.OnChange := DoChange;
  inherited Create(View, ADefaultKind, ADefaultColor);
  FWidth := 16;
  FHeight := 16;
  FPosition := TDrawablePosition.Left;
  FPadding := 4;
end;

procedure TDrawableIcon.CreateBrush(var Value: TBrush; IsDefault: Boolean);
begin
  if Assigned(Value) then
    FreeAndNil(Value);
  if IsDefault then
    Value := TViewImagesBrush.Create(TBrushKind(FDefaultKind), FDefaultColor)
  else
    Value := TViewImagesBrush.Create(TBrushKind.None, TAlphaColorRec.Null);
  TViewImagesBrush(Value).FOwner := Self;
  Value.OnChanged := DoChange;
end;

destructor TDrawableIcon.Destroy;
begin
  FImageLink.DisposeOf;
  inherited;
end;

procedure TDrawableIcon.Draw(Canvas: TCanvas);
var
  ImageIndex: Integer;
begin
  inherited Draw(Canvas);
  ImageIndex := GetStateImageIndex();
  if (ImageIndex >= 0) and Assigned(FImageLink.Images) then
    DrawImage(Canvas, ImageIndex, GetDrawRect(0, 0, FView.GetWidth, FView.GetHeight));
end;

procedure TDrawableIcon.DrawImage(Canvas: TCanvas; Index: Integer;
  const R: TRectF);
var
  Images: TCustomImageList;
  Bitmap: TBitmap;
  BitmapSize: TSize;
  BitmapRect: TRectF;
begin
  if FView.InVisible then
    Exit;
  Images := GetImages;
  if Assigned(Images) and (Index >= 0) and (Index < Images.Count) then begin
    BitmapSize := TSize.Create(FWidth * 2, FHeight * 2);
    if BitmapSize.IsZero then
      Exit;
    Bitmap := Images.Bitmap(BitmapSize, Index);
    if Bitmap <> nil then begin
      BitmapRect := TRectF.Create(0, 0, Bitmap.Width, Bitmap.Height);
      Canvas.DrawBitmap(Bitmap, BitmapRect, R, FView.GetOpacity, False);
    end;
  end;
end;

procedure TDrawableIcon.DrawStateTo(Canvas: TCanvas; const R: TRectF; AState: TViewState);
var
  ImageIndex: Integer;
begin
  inherited DrawStateTo(Canvas, R, AState);
  ImageIndex := GetStateImageIndex(AState);
  if (ImageIndex >= 0) and Assigned(FImageLink.Images) then
    DrawImage(Canvas, ImageIndex, R);
end;

function TDrawableIcon.GetComponent: TComponent;
begin
  Result := FView.GetComponent;
end;

function TDrawableIcon.GetEmpty: Boolean;
begin
  if GetStateImageIndex >= 0 then
    Result := not Assigned(FImageLink.Images)
  else begin
    Result := (FWidth <= 0) or (FHeight <= 0);
    if not Result then
      Result := inherited GetEmpty;
  end;
end;

function TDrawableIcon.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

function TDrawableIcon.GetImageList: TBaseImageList;
begin
  Result := GetImages;
end;

function TDrawableIcon.GetImages: TCustomImageList;
begin
  if Assigned(FImageLink.Images) then
    Result := TCustomImageList(FImageLink.Images)
  else
    Result := nil;
end;

function TDrawableIcon.GetStateImageIndex: Integer;
begin
  if Assigned(FView) then
    Result := GetStateImageIndex(FView.GetDrawState)
  else
    Result := -1;
end;

function TDrawableIcon.GetStateImageIndex(State: TViewState): Integer;
var
  V: TBrush;
begin
  Result := -1;
  if Assigned(FView) then begin
    V := GetStateImagesItem(State);
    if Assigned(V) then
      Result := TViewImagesBrush(V).FImageIndex;
  end;
end;

procedure TDrawableIcon.ImagesChanged;
begin
  DoChange(Self);
end;

function TDrawableIcon.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := S_OK
  else Result := E_NOINTERFACE
end;

procedure TDrawableIcon.SetHeight(const Value: Integer);
begin
  if FHeight <> Value then begin
    FHeight := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableIcon.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

procedure TDrawableIcon.SetImageList(const Value: TBaseImageList);
begin
  ValidateInheritance(Value, TCustomImageList);
  SetImages(TCustomImageList(Value));
end;

procedure TDrawableIcon.SetImages(const Value: TCustomImageList);
begin
  FImageLink.Images := Value;
end;

procedure TDrawableIcon.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then begin
    FPadding := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableIcon.SetPosition(const Value: TDrawablePosition);
begin
  if FPosition <> Value then begin
    FPosition := Value;
    DoChange(Self);
  end;
end;

procedure TDrawableIcon.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then begin
    FWidth := Value;
    DoChange(Self);
  end;
end;

function TDrawableIcon._AddRef: Integer;
begin
  Result := -1;
end;

function TDrawableIcon._Release: Integer;
begin
  Result := -1;
end;

{ TViewColor }

procedure TViewColor.Assign(Source: TPersistent);
var
  Src: TViewColor;
begin
  if Source = nil then begin
    Self.FPressed := TAlphaColorRec.Null;
    Self.FFocused := TAlphaColorRec.Null;
    Self.FHovered := TAlphaColorRec.Null;
    Self.FSelected := TAlphaColorRec.Null;
    Self.FChecked := TAlphaColorRec.Null;
    Self.FEnabled := TAlphaColorRec.Null;
    Self.FActivated := TAlphaColorRec.Null;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end else if Source is TViewColor then begin
    Src := TViewColor(Source);
    Self.FDefault := Src.FDefault;
    Self.FPressed := Src.FPressed;
    Self.FFocused := Src.FFocused;
    Self.FHovered := Src.FHovered;
    Self.FSelected := Src.FSelected;
    Self.FChecked := Src.FChecked;
    Self.FEnabled := Src.FEnabled;
    Self.FActivated := Src.FActivated;
    Self.FHintText := Src.FHintText;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end else
    inherited;
end;

constructor TViewColor.Create(const ADefaultColor: TAlphaColor);
begin
  FDefault := ADefaultColor;
  FPressed := TAlphaColorRec.Null;
  FFocused := TAlphaColorRec.Null;
  FHovered := TAlphaColorRec.Null;
  FSelected := TAlphaColorRec.Null;
  FChecked := TAlphaColorRec.Null;
  FEnabled := TAlphaColorRec.Null;
  FActivated := TAlphaColorRec.Null;
  FHintText := TAlphaColorRec.Gray;
end;

function TViewColor.ColorActivatedStored: Boolean;
begin
  Result := GetColorStoreState(8);
end;

function TViewColor.ColorCheckedStored: Boolean;
begin
  Result := GetColorStoreState(6);
end;

function TViewColor.ColorDefaultStored: Boolean;
begin
  Result := GetColorStoreState(1);
end;

function TViewColor.ColorEnabledStored: Boolean;
begin
  Result := GetColorStoreState(7);
end;

function TViewColor.ColorFocusedStored: Boolean;
begin
  Result := GetColorStoreState(3);
end;

function TViewColor.ColorHoveredStored: Boolean;
begin
  Result := GetColorStoreState(4);
end;

function TViewColor.ColorPressedStored: Boolean;
begin
  Result := GetColorStoreState(2);
end;

function TViewColor.ColorSelectedStored: Boolean;
begin
  Result := GetColorStoreState(5);
end;

destructor TViewColor.Destroy;
begin
  inherited;
end;

procedure TViewColor.DoChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then
    FOnChanged(Sender);
end;

function TViewColor.GetColor(State: TViewState): TAlphaColor;
begin
  case State of
    TViewState.None: Result := FDefault;
    TViewState.Pressed: Result := FPressed;
    TViewState.Focused: Result := FFocused;
    TViewState.Hovered: Result := FHovered;
    TViewState.Selected: Result := FSelected;
    TViewState.Checked: Result := FChecked;
    TViewState.Enabled: Result := FEnabled;
    TViewState.Activated: Result := FActivated;
  else
    if Ord(State) = 8 then
      Result := FHintText
    else
      raise EDrawableError.Create(Format(SInvViewValue, [Integer(State)]));
  end;
end;

function TViewColor.GetColorStoreState(const Index: Integer): Boolean;
begin
  Result := (FColorStoreState and Index) <> 0;
end;

function TViewColor.GetStateColor(State: TViewState): TAlphaColor;
begin
  Result := GetColor(State);
  if (Result = TAlphaColorRec.Null) and (State <> TViewState.None) then begin
    if (State = TViewState.Pressed) and (FFocused <> TAlphaColorRec.Null) then
      Result := FFocused
    else
      Result := FDefault
  end;
end;

function TViewColor.GetValue(const Index: Integer): TAlphaColor;
begin
  Result := GetColor(TViewState(Index));
end;

procedure TViewColor.SetActivated(const Value: TAlphaColor);
begin
  if FActivated <> Value then begin
    FActivated := Value;
    ActivatedChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetChecked(const Value: TAlphaColor);
begin
  if FChecked <> Value then begin
    FChecked := Value;
    CheckedChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetColor(State: TViewState; const Value: TAlphaColor);
begin
  case State of
    TViewState.None: FDefault := Value;
    TViewState.Pressed: FPressed := Value;
    TViewState.Focused: FFocused := Value;
    TViewState.Hovered: FHovered := Value;
    TViewState.Selected: FSelected := Value;
    TViewState.Checked: FChecked := Value;
    TViewState.Enabled: FEnabled := Value;
    TViewState.Activated: FActivated := Value;
  else
    if Ord(State) = 8 then
      FHintText := Value
    else
      raise EDrawableError.Create(Format(SInvViewValue, [Integer(State)]));
  end;
  DoChange(Self);
end;

procedure TViewColor.SetColorStoreState(const Index: Integer;
  const Value: Boolean);
begin
  if Value then
    FColorStoreState := (FColorStoreState or Cardinal(Index))
  else
    FColorStoreState := (FColorStoreState and (not Index));
end;

procedure TViewColor.SetDefault(const Value: TAlphaColor);
begin
  if Value <> FDefault then begin
    FDefault := Value;
    DefaultChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetEnabled(const Value: TAlphaColor);
begin
  if FEnabled <> Value then begin  
    FEnabled := Value;
    EnabledChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetFocused(const Value: TAlphaColor);
begin
  if Focused <> Value then begin  
    FFocused := Value;
    FocusedChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetHovered(const Value: TAlphaColor);
begin
  if FHovered <> Value then begin  
    FHovered := Value;
    HoveredChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetPressed(const Value: TAlphaColor);
begin
  if FPressed <> Value then begin  
    FPressed := Value;
    PressedChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetSelected(const Value: TAlphaColor);
begin
  if FSelected <> Value then begin  
    FSelected := Value;
    SelectedChange := True;
    DoChange(Self);
  end;
end;

procedure TViewColor.SetValue(const Index: Integer; const Value: TAlphaColor);
begin
  SetColor(TViewState(Index), Value);
end;  

{ TTextColor }

function TTextColor.GetHintText: TAlphaColor;
begin
  Result := FHintText;
end;

procedure TTextColor.SetHintText(const Value: TAlphaColor);
begin
  if FHintText <> Value then begin  
    FHintText := Value;
    DoChange(Self);
  end;
end;

{ TViewLayout }

procedure TViewLayout.Assign(Source: TPersistent);
var
  SaveChange: TNotifyEvent;
  Src: TViewLayout;
begin
  if Source is TViewLayout then begin
    SaveChange := FOnChanged;
    FOnChanged := nil;
    Src := TViewLayout(Source);
    FToLeftOf := Src.FToLeftOf;
    FToRightOf := Src.FToRightOf;
    FAbove := Src.FAbove;
    FBelow := Src.FBelow;
    FAlignBaseline := Src.FAlignBaseline;
    FAlignLeft := Src.FAlignLeft;
    FAlignTop := Src.FAlignTop;
    FAlignRight := Src.FAlignRight;
    FAlignBottom := Src.FAlignBottom;

    FAlignParentLeft := Src.FAlignParentLeft;
    FAlignParentTop := Src.FAlignParentTop;
    FAlignParentRight := Src.FAlignParentRight;
    FAlignParentBottom := Src.FAlignParentBottom;
    FCenterInParent := Src.FCenterInParent;
    FCenterHorizontal := Src.FCenterHorizontal;
    FCenterVertical := Src.FCenterVertical;

    FOnChanged := SaveChange;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end else
    inherited;
end;

constructor TViewLayout.Create(View: IView);
begin
  FView := View;
end;

destructor TViewLayout.Destroy;
begin
  inherited;
end;

procedure TViewLayout.DoChange();
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

function TViewLayout.GetHeight: TViewSize;
begin
  Result := FView.HeightSize;
end;

function TViewLayout.GetWidth: TViewSize;
begin
  Result := FView.WidthSize;
end;

function TViewLayout.IsEmpty: Boolean;
begin
  Result := not (Assigned(FAbove) or Assigned(FAlignBaseline) or
    Assigned(FAlignBottom) or Assigned(FAlignLeft) or Assigned(FAlignRight) or
    Assigned(FAlignTop) or Assigned(FBelow) or Assigned(FToLeftOf) or
    Assigned(FToRightOf));
end;

procedure TViewLayout.SetAbove(const Value: TControl);
begin
  SetValue(FAbove, Value);
end;

procedure TViewLayout.SetAlignBaseline(const Value: TControl);
begin
  SetValue(FAlignBaseline, Value);
end;

procedure TViewLayout.SetAlignBottom(const Value: TControl);
begin
  SetValue(FAlignBottom, Value);
end;

procedure TViewLayout.SetAlignLeft(const Value: TControl);
begin
  SetValue(FAlignLeft, Value);
end;

procedure TViewLayout.SetAlignParentBottom(const Value: Boolean);
begin
  SetValue(FAlignParentBottom, Value);
end;

procedure TViewLayout.SetAlignParentLeft(const Value: Boolean);
begin
  SetValue(FAlignParentLeft, Value);
end;

procedure TViewLayout.SetAlignParentRight(const Value: Boolean);
begin
  SetValue(FAlignParentRight, Value);
end;

procedure TViewLayout.SetAlignParentTop(const Value: Boolean);
begin
  SetValue(FAlignParentTop, Value);
end;

procedure TViewLayout.SetAlignRight(const Value: TControl);
begin
  SetValue(FAlignRight, Value);
end;

procedure TViewLayout.SetAlignTop(const Value: TControl);
begin
  SetValue(FAlignTop, Value);
end;

procedure TViewLayout.SetBelow(const Value: TControl);
begin
  SetValue(FBelow, Value);
end;

procedure TViewLayout.SetCenterHorizontal(const Value: Boolean);
begin
  SetValue(FCenterHorizontal, Value);
end;

procedure TViewLayout.SetCenterInParent(const Value: Boolean);
begin
  SetValue(FCenterInParent, Value);
end;

procedure TViewLayout.SetCenterVertical(const Value: Boolean);
begin
  SetValue(FCenterVertical, Value);
end;

procedure TViewLayout.SetHeight(const Value: TViewSize);
begin
  FView.HeightSize := Value;
end;

procedure TViewLayout.SetToLeftOf(const Value: TControl);
begin
  SetValue(FToLeftOf, Value);
end;

procedure TViewLayout.SetToRightOf(const Value: TControl);
begin
  SetValue(FToRightOf, Value);
end;

procedure TViewLayout.SetValue(var Dest: Boolean; const Value: Boolean);
begin
  if Dest <> Value then begin
    Dest := Value;
    DoChange();
  end;
end;

procedure TViewLayout.SetValue(var Dest: TControl; const Value: TControl);
var
  Tmp: TControl;
begin
  if Dest <> Value then begin
    if Assigned(Value) then begin
      if Value = TObject(FView) then
        raise EViewLayoutError.Create(SNotAllowSelf);
      if Value.Parent <> FView.ParentControl then
        raise EViewLayoutError.Create(SMustSameParent);
      if not (csLoading in FView.GetComponentState) then begin
        Tmp := Dest;
        Dest := Value;
        try
          CheckRecursionState(FView);
        finally
          Dest := Tmp;
        end;
      end;
    end;
    Dest := Value;
    DoChange();
  end;
end;

procedure TViewLayout.SetWidth(const Value: TViewSize);
begin
  FView.WidthSize := Value;
end;

{ TViewBase }

function TViewBase.GetBackground: TDrawable;
begin
  Result := nil;
end;

function TViewBase.GetMaxHeight: Single;
begin
  Result := 0;
end;

function TViewBase.GetMaxWidth: Single;
begin
  Result := 0;
end;

function TViewBase.GetMinHeight: Single;
begin
  Result := 0;
end;

function TViewBase.GetMinWidth: Single;
begin
  Result := 0;
end;

function TViewBase.GetViewBackground: TDrawable;
begin
  Result := nil;
end;

function TViewBase.GetViewStates: TViewStates;
begin
  Result := [];
  if Self.FIsFocused then
    Include(Result, TViewState.Focused);
  if Self.Pressed then
    Include(Result, TViewState.Pressed);
end;

{ TView }

procedure TView.AfterPaint;
begin
  inherited;
  FInvaliding := False;
end;

function TView.AllowUseLayout: Boolean;
begin
  Result := (not (csDesigning in ComponentState)) or
    (Assigned(ParentControl)) and (ParentControl is TRelativeLayout);
end;

function TView.CanAnimation: Boolean;
begin
  Result := False;
end;

function TView.CanRePaintBk(const View: IView; State: TViewState): Boolean;
begin
  Result := CanRepaint and EmptyBackground(View.Background, State);
end;

function TView.EmptyBackground(const V: TDrawable;
  const State: TViewState): Boolean;
begin
  Result := Assigned(V) and
    (Assigned(V.GetStateBrush(State)) or
    ((V is TDrawableBorder) and Assigned(TDrawableBorder(V)._Border) and
    (TDrawableBorder(V)._Border.Color.GetColor(State) and $FF000000 > 0)));
end;

procedure TView.Click;
begin
  {$IFNDEF MSWINDOWS}
  if Abs(FDownUpOffset) > 10 then // ��ֹ����ʱ��������¼�
    Exit;
  if Assigned(OnClick) then
    PlayClickEffect;
  {$ENDIF}
  inherited Click;
end;

constructor TView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetAcceptsControls(False);
  ClipChildren := True;
  HitTest := False;
  FAdjustViewBounds := True;
  FRecalcInVisible := True;
  FViewState := [];
  FDrawState := TViewState.None;
  if csDesigning in ComponentState then begin
    FBackground := CreateBackground();
    FLayout := TViewLayout.Create(Self);
    FLayout.OnChanged := DoLayoutChanged;
  end;
  WidthSize := TViewSize.CustomSize;
  DisableFocusEffect := True;
end;

function TView.CreateBackground: TDrawable;
begin
  Result := TDrawableBorder.Create(Self);
  Result.OnChanged := DoBackgroundChanged;
end;

procedure TView.DecChildState(State: TViewState);
var
  I: Integer;
  View: IView;
begin
  if State = TViewState.None then Exit;
  if (csDestroying in ComponentState) or (csDesigning in ComponentState) then Exit;
  for I := 0 to Controls.Count - 1 do begin
    if Supports(Controls.Items[I], IView, View) then
      View.DecViewState(State);
  end;
end;

procedure TView.DecViewState(const State: TViewState);
begin
  Exclude(FViewState, State);
  FDrawState := GetRealDrawState;
  DecChildState(State);
end;

destructor TView.Destroy;
begin
  FreeScrollbar();
  FreeAndNil(FBackground);
  FreeAndNil(FLayout);
  inherited Destroy;
end;

procedure TView.DoActivate;
begin
  //IncViewState(TViewState.Activated);
  inherited DoActivate;
end;

procedure TView.DoAdjustViewBounds(var ANewWidth, ANewHeight: Single);
var
  AMaxW, AMaxH: Single;
begin
  if FAdjustViewBounds then begin
    AMaxW := FMaxWidth;
    AMaxH := FMaxHeight;

    if Assigned(ParentView) then begin
      if (AMaxW <= 0) and (WidthSize = TViewSize.WrapContent) then
        AMaxW := ParentView.MaxWidth;
      if (AMaxH <= 0) and (HeightSize = TViewSize.WrapContent) then
        AMaxH := ParentView.MaxHeight;
    end;

    if (AMaxW > 0) and (ANewWidth > AMaxW) then
      ANewWidth := AMaxW;
    if (AMaxH > 0) and (ANewHeight > AMaxH) then
      ANewHeight := AMaxH;
    if (FMinWidth > 0) and (ANewWidth < FMinWidth) then
      ANewWidth := FMinWidth;
    if (FMinHeight > 0) and (ANewHeight < FMinHeight) then
      ANewHeight := FMinHeight;
  end;
end;

procedure TView.DoBackgroundChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TView.DoChangeSize(var ANewWidth, ANewHeight: Single);
begin
  DoRecalcSize(ANewWidth, ANewHeight);
  DoAdjustViewBounds(ANewWidth, ANewHeight);
end;

procedure TView.DoCheckedChange;
begin
end;

procedure TView.DoDeactivate;
begin
  DecViewState(TViewState.Activated);
  inherited DoDeactivate;
end;

procedure TView.DoEndUpdate;
begin
  inherited DoEndUpdate;
  TempMaxHeight := 0;
  TempMaxWidth := 0;
end;

function TView.DoGetUpdateRect: TRectF;
var
  LastFocus: Boolean;
begin
  LastFocus := CanFocus;
  CanFocus := False;
  Result := inherited DoGetUpdateRect;
  CanFocus := LastFocus;
end;

procedure TView.DoGravity;
begin
  Repaint;
end;

procedure TView.DoInVisibleChange;
begin
  if FInVisible then begin
    FAbsoluteInVisible := True;
    FRecalcInVisible := False;
  end else
    RecalcInVisible();
end;

procedure TView.DoLayoutChanged(Sender: TObject);
begin
  HandleSizeChanged;
end;

procedure TView.DoMatrixChanged(Sender: TObject);
begin
  inherited DoMatrixChanged(Sender);
  if Assigned(FBadgeView) then begin 
    FBadgeView.SetVisible(Visible);
    if Visible then
      FBadgeView.Realign;
  end;
end;

procedure TView.DoMaxSizeChange;
begin
  HandleSizeChanged;
end;

procedure TView.DoMinSizeChange;
begin
  HandleSizeChanged;
end;

procedure TView.DoMouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  if (csDesigning in ComponentState) or FInVisible then Exit;
  if (TMouseButton.mbLeft = Button) and (Clickable or (not (Self is TViewGroup))) then begin
    IncViewState(TViewState.Pressed);
    if CanRePaintBk(Self, TViewState.Pressed) then Repaint;
  end;
  {$IFDEF MSWINDOWS}
  if FCaptureDragForm then
    StartWindowDrag;
  {$ENDIF}
end;

procedure TView.DoMouseEnter;
begin
  inherited DoMouseEnter;
  if (csDesigning in ComponentState) or FInVisible then Exit;
  IncViewState(TViewState.Hovered);
  if CanRePaintBk(Self, TViewState.Hovered) then Repaint;
end;

procedure TView.DoMouseLeave;
begin
  inherited DoMouseLeave;
  DecViewState(TViewState.Hovered);
  if (csDesigning in ComponentState) or FInVisible then Exit;
  if CanRePaintBk(Self, FDrawState) then begin
    FInvaliding := False;
    Repaint;
  end;
end;

procedure TView.DoMouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  if (TMouseButton.mbLeft = Button) and (Clickable or (not (Self is TViewGroup))) then begin
    DecViewState(TViewState.Pressed);
    if (csDesigning in ComponentState) or FInVisible then
      Exit;
    if CanRePaintBk(Self, TViewState.Pressed) then Repaint;
  end;
end;

function TView.GetCaptureDragForm: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := FCaptureDragForm;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TView.GetClickable: Boolean;
begin
  Result := HitTest;
end;

function TView.GetComponent: TComponent;
begin
  Result := Self;
end;

function TView.GetComponentState: TComponentState;
begin
  Result := ComponentState;
end;

function TView.GetContentBounds: TRectD;
begin
  Result := TRectD.Empty;
end;

function TView.GetDrawState: TViewState;
begin
  Result := FDrawState;
end;

function TView.GetGravity: TLayoutGravity;
begin
  Result := FGravity;
end;

function TView.GetHeightSize: TViewSize;
begin
  Result := FHeightSize;
end;

function TView.GetHScrollBar: TScrollBar;
begin
  Result := nil;
end;

function TView.GetInVisible: Boolean;
begin
  Result := FInVisible;
end;

function TView.GetIsChecked: Boolean;
begin
  Result := TViewState.Checked in FViewState;
end;

function TView.GetLayout: TViewLayout;
begin
  if not AllowUseLayout then
    Result := nil
  else begin
    if not Assigned(FLayout) then begin
      FLayout := TViewLayout.Create(Self);
      FLayout.OnChanged := DoLayoutChanged;
    end;
    Result := FLayout;
  end;
end;

function TView.GetMargin: string;
begin
  Result := GetBoundsFloat(Margins);
end;

function TView.GetMaxHeight: Single;
begin
  Result := FMaxHeight;
end;

function TView.GetMaxWidth: Single;
begin
  Result := FMaxWidth;
end;

function TView.GetMinHeight: Single;
begin
  Result := FMinHeight;
end;

function TView.GetMinWidth: Single;
begin
  Result := FMinWidth;
end;

class function TView.GetNavigationBarHeight: Single;
begin
  Result := NavigationBarHeight;
end;

function TView.GetOpacity: Single;
begin
  Result := AbsoluteOpacity;
end;

function TView.GetOrientation: TOrientation;
begin
  Result := FOrientation;
end;

function TView.GetPaddings: string;
begin
  Result := GetBoundsFloat(Padding);
end;

function TView.GetParentControl: TControl;
begin
  Result := ParentControl;
end;

function TView.GetParentForm: TCustomForm;
var
  P: TFmxObject;
begin
  Result := nil;
  P := Self;
  while P <> nil do begin
    if P is TCustomForm then begin
      Result := P as TCustomForm;
      Break;
    end else
      P := P.Parent;
  end;
end;

function TView.GetParentMaxHeight: Single;
begin
  if FMaxHeight > 0 then
    Result := FMaxHeight
  else begin
    if Assigned(ParentView) then
      Result := TView(Parent).GetParentMaxHeight - Margins.Top - Margins.Bottom
    else begin
      if HeightSize = TViewSize.WrapContent then begin
        if Parent is TControl then
          Result := TControl(Parent).Height
        else
          Result := 0
      end else
        Result := Height;
    end;
  end;
end;

function TView.GetParentMaxWidth: Single;
begin
  if FMaxWidth > 0 then
    Result := FMaxWidth
  else begin
    if Assigned(ParentView) then
      Result := TView(Parent).GetParentMaxWidth - Margins.Left - Margins.Right
    else
      Result := 0;
  end;
end;

function TView.GetParentView: IViewGroup;
begin
  Supports(Parent, IViewGroup, Result);
end;

function TView.GetPosition: TPosition;
begin
  Result := Position;
end;

function TView.GetSceneScale: Single;
begin
  Result := 0;
  if Scene <> nil then
    Result := Scene.GetSceneScale;
  if Result <= 0 then
    Result := 1;
end;

function TView.GetScrollSmallChangeFraction: Single;
begin
  Result := SmallChangeFraction;
end;

class function TView.GetStatusHeight: Single;
begin
  Result := StatusHeight;
end;

function TView.GetViewBackground: TDrawable;
begin
  if not Assigned(FBackground) then
    FBackground := CreateBackground();
  Result := FBackground;
end;

function TView.GetViewRect: TRectF;
begin
  Result := RectF(Padding.Left, Padding.Top,
    Width - Padding.Right + Padding.Left, Height - Padding.Bottom + Padding.Top);
end;

function TView.GetViewRectD: TRectD;
begin
  Result := RectD(Padding.Left, Padding.Top,
    Width - Padding.Right + Padding.Left, Height - Padding.Bottom + Padding.Top);
end;

function TView.GetViewStates: TViewStates;
begin
  Result := FViewState;
end;

function TView.GetVScrollBar: TScrollBar;
begin
  Result := nil;
end;

function TView.GetWeight: Single;
begin
  Result := FWeight;
end;

function TView.GetWidthSize: TViewSize;
begin
  Result := FWidthSize;
end;

class procedure TView.SetRttiValue(Instance: TObject; const Name: string; const Value: TValue);
var
  FType: TRttiType;
  FFiled: TRttiField;
  FContext: TRttiContext;
begin
  FContext := TRttiContext.Create;
  try
    FType := FContext.GetType(Instance.ClassType);
    FFiled := FType.GetField(Name);
    if Assigned(FFiled) then
      FFiled.SetValue(Instance, Value);
  finally
    FContext.Free;
  end;
end;

class procedure TView.SetRttiValue<T>(Instance: TObject; const Name: string;
  const Value: T);
var
  FType: TRttiType;
  FFiled: TRttiField;
  FContext: TRttiContext;
begin
  FContext := TRttiContext.Create;
  try
    FType := FContext.GetType(Instance.ClassType);
    FFiled := FType.GetField(Name);
    if not Assigned(FFiled) then Exit;
    if FFiled.FieldType.TypeKind <> PTypeInfo(TypeInfo(T)).Kind then
      Exit;
    FFiled.SetValue(Instance, TValue.From(Value));
  finally
    FContext.Free;
  end;
end;

class function TView.GetRttiValue(Instance: TObject; const Name: string): TValue;
var
  FType: TRttiType;
  FFiled: TRttiField;
  FContext: TRttiContext;
begin
  FContext := TRttiContext.Create;
  try
    FType := FContext.GetType(Instance.ClassType);
    FFiled := FType.GetField(Name);
    if Assigned(FFiled) then
      Result := FFiled.GetValue(Instance)
    else
      Result := nil;
  finally
    FContext.Free;
  end;
end;

class function TView.GetRttiValue<T>(Instance: TObject; const Name: string): T;
var
  FType: TRttiType;
  FFiled: TRttiField;
  FContext: TRttiContext;
begin
  FContext := TRttiContext.Create;
  try
    FType := FContext.GetType(Instance.ClassType);
    FFiled := FType.GetField(Name);
    if not Assigned(FFiled) then  
      Result := T(nil)
    else
      Result := FFiled.GetValue(Instance).AsType<T>();
  finally
    FContext.Free;
  end;
end;

function TView.GetRealDrawState: TViewState;
begin
  if FViewState = [] then
    Result := TViewState.None
  else begin
    if TViewState.Enabled in FViewState then
      Result := TViewState.Enabled
    else if TViewState.Pressed in FViewState then
      Result := TViewState.Pressed
    else if TViewState.Focused in FViewState then
      Result := TViewState.Focused
    else if TViewState.Selected in FViewState then
      Result := TViewState.Selected
    else if TViewState.Checked in FViewState then
      Result := TViewState.Checked
    else if TViewState.Activated in FViewState then
      Result := TViewState.Activated
    else if TViewState.Hovered in FViewState then
      Result := TViewState.Hovered
    else
      Result := TViewState.None
  end;
end;

class function TView.GetRttiObject(Instance: TObject; const Name: string): TObject;
var
  V: TValue;
begin
  V := GetRttiValue(Instance, Name);
  if (V.IsEmpty) or (not V.IsObject) then
    Result := nil
  else
    Result := V.AsObject;
end;

procedure TView.HandleSizeChanged;
begin
  inherited HandleSizeChanged;
  if Assigned(ParentView) then begin
    if (csLoading in ComponentState) and (Children <> nil) then
      Exit;
    ParentControl.RecalcSize;
  end;
end;

procedure TView.HitTestChanged;
begin
  inherited HitTestChanged;
  if HitTest and (not AutoCapture) then
    AutoCapture := True;
end;

procedure TView.ImagesChanged;
begin
  Repaint;
end;

procedure TView.IncChildState(State: TViewState);
var
  I: Integer;
  View: IView;
begin
  if State = TViewState.None then Exit;
  if (csDestroying in ComponentState) or (csDesigning in ComponentState) then Exit;
  for I := 0 to Controls.Count - 1 do begin
    if (State = TViewState.Pressed) and Controls.Items[I].HitTest then
      Continue;
    if Supports(Controls.Items[I], IView, View) then begin
      if (State = TViewState.Hovered) and (Assigned(View.Background)) and Assigned(View.Background.FHovered) then begin
        if View.Background.FHovered.Kind <> TBrushKind.None then
          Continue;
      end;
      View.IncViewState(State);
    end;
  end;
end;

procedure TView.IncViewState(const State: TViewState);
begin
  Include(FViewState, State);
  FDrawState := GetRealDrawState;
  IncChildState(State);
end;

procedure TView.InitScrollbar;
begin
end;

procedure TView.InternalAlign;
begin
end;

procedure TView.Invalidate;
begin
  if not FInvaliding then
  begin
    InvalidateRect(LocalRect);
    FInvaliding := True;
  end;
end;

{$IFDEF ANDROID}
class procedure TView.InitAudioManager();
var
  NativeService: JObject;
begin
  NativeService := TAndroidHelper.Context.getSystemService(TJContext.JavaClass.AUDIO_SERVICE);
  if not Assigned(NativeService) then
    Exit;
  FAudioManager := TJAudioManager.Wrap((NativeService as ILocalObject).GetObjectID);
end;
{$ENDIF}

function TView.IsActivated: Boolean;
begin
  Result := TViewState.Activated in FViewState;
end;

function TView.IsAdjustLayout: Boolean;
begin
  Result := True;
end;

function TView.IsAutoSize: Boolean;
begin
  Result := False;
end;

function TView.IsDesignerControl(Control: TControl): Boolean;
begin
  Result := (csDesigning in ComponentState) and
    (Supports(Control, IDesignerControl) or
    (Control.ClassNameIs('TDesignRectangle')));
end;

function TView.IsDrawing: Boolean;
begin
  Result := FDrawing;
end;

function TView.IsHovered: Boolean;
begin
  Result := TViewState.Hovered in FViewState;
end;

function TView.IsPressed: Boolean;
begin
  Result := TViewState.Pressed in FViewState;
end;

function TView.GetAbsoluteInVisible: Boolean;
var
  PV: IViewGroup;
begin
  if FRecalcInVisible then begin
    if FInVisible then
      FAbsoluteInVisible := True
    else begin
      PV := ParentView;
      if Assigned(PV) then
        FAbsoluteInVisible := PV.GetAbsoluteInVisible
      else
        FAbsoluteInVisible := FInVisible;
    end;
    FRecalcInVisible := False;
  end;
  Result := FAbsoluteInVisible;
end;

function TView.GetAdjustViewBounds: Boolean;
begin
  Result := FAdjustViewBounds;
end;

function TView.GetAniCalculations: TScrollCalculations;
begin
  Result := nil;
end;

function TView.GetBackground: TDrawable;
begin
  Result := FBackground;
end;

function TView.GetBadgeView: IViewBadge;
begin
  Result := FBadgeView;
end;

procedure TView.Loaded;
begin
  inherited Loaded;
end;

procedure TView.MouseClick(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  {$IFDEF POSIX}
  FDownUpOffset := Y - FDownUpOffset;
  {$ENDIF}
  inherited;
end;

procedure TView.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  {$IFDEF POSIX}
  FDownUpOffset := Y;
  {$ENDIF}
  inherited MouseDown(Button, Shift, X, Y);
  DoMouseDown(Button, Shift, X, Y);
end;

procedure TView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited MouseUp(Button, Shift, X, Y);
  DoMouseUp(Button, Shift, X, Y);
end;

procedure TView.DoOrientation;
begin
end;

procedure TView.DoRecalcSize(var AWidth, AHeight: Single);
begin
end;

procedure TView.DoResize;
begin
  Resize;
end;

procedure TView.DoSetScrollBarValue(Scroll: TScrollBar; const Value, ViewportSize: Double);
begin
  //Scroll.ValueRange.Min := Min(Value, ContentBounds.Top);
  //Scroll.ValueRange.Max := Max(Value + ViewportSize, ContentBounds.Bottom);
  if Scroll.Height > Scroll.Width then begin
    Scroll.ValueRange.Min := Min(Value, ContentBounds.Top);
    Scroll.ValueRange.Max := Max(Value + ViewportSize, ContentBounds.Bottom);
  end else begin
    Scroll.ValueRange.Min := Min(Value, ContentBounds.Left);
    Scroll.ValueRange.Max := Max(Value + ViewportSize, ContentBounds.Right);
  end;
  Scroll.ValueRange.ViewportSize := ViewportSize;
  Scroll.ValueD := Value;
end;

function TView.DoSetSize(const ASize: TControlSize;
  const NewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
  var ALastWidth, ALastHeight: Single): Boolean;
begin
  DoChangeSize(ANewWidth, ANewHeight);
  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight,
    ALastWidth, ALastHeight);
end;

procedure TView.DoWeight;
begin
  HandleSizeChanged;
end;

procedure TView.EnabledChanged;
begin
  inherited EnabledChanged;
  if Enabled then begin
    DecViewState(TViewState.Enabled);
  end else begin
    IncViewState(TViewState.Enabled);
  end;
end;

function TView.FindAndCloneStyleResource<T>(const AStyleLookup: string;
  var AResource: T): Boolean;
var
  StyleObject: TFmxObject;
begin
  StyleObject := nil;
  if FindStyleResource(AStyleLookup, StyleObject) then
    AResource := T(FindStyleResource(AStyleLookup, True));
  Result := StyleObject <> nil;
end;

function TView.FindStyleResource<T>(const AStyleLookup: string;
  var AResource: T): Boolean;
var
  StyleObject: TFmxObject;
begin
  StyleObject := FindStyleResource(AStyleLookup, False);
  Result := StyleObject is T;
  if Result then
    AResource := T(StyleObject);
end;

procedure TView.FreeScrollbar;
begin
end;

procedure TView.Paint;
begin
  if not FDrawing then begin
    inherited Paint;
    if FIsFocused then begin
      Include(FViewState, TViewState.Focused);
      FDrawState := GetRealDrawState;
    end else begin
      Exclude(FViewState, TViewState.Focused);
      if FDrawState = TViewState.Focused then
        FDrawState := GetRealDrawState;
    end;
    FDrawing := True;
    Canvas.BeginScene();
    try
      PaintBackground();
      if (csDesigning in ComponentState) and not Locked then
        DrawDesignBorder;
    finally
      Canvas.EndScene;
      FDrawing := False;
    end;
  end;
end;

procedure TView.PaintBackground;
begin
  if Assigned(FBackground) and (AbsoluteInVisible = False) then
    FBackground.Draw(Canvas);
end;

procedure TView.PlayClickEffect;
begin
  {$IFDEF ANDROID}
  PlaySoundEffect(0); // SoundEffectConstants.CLICK
  {$ENDIF}
end;

procedure TView.PlaySoundEffect(ASoundConstant: Integer);
{$IFDEF ANDROID}
var
  RingerMode: Integer;
begin
  if not Assigned(FAudioManager) then
    Exit;
  RingerMode := FAudioManager.getRingerMode;
  // ����������ʱ����������
  if (ringerMode = TJAudioManager.JavaClass.RINGER_MODE_SILENT) or
    (ringerMode = TJAudioManager.JavaClass.RINGER_MODE_VIBRATE) then
    Exit;
  FAudioManager.playSoundEffect(ASoundConstant);
{$ELSE}
begin
{$ENDIF}
end;

function TView.PointInObject(X, Y: Single): Boolean;
begin
  if AbsoluteInVisible then
    Result := False
  else
    Result := inherited PointInObject(X, Y);
end;

procedure TView.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
end;

procedure TView.RecalcInVisible;
var
  I: Integer;
  Item: TControl;
begin
  if FRecalcInVisible then Exit;
  FRecalcInVisible := True;
  for I := 0 to ControlsCount - 1 do begin
    Item := Controls[I];
    if Item is TView then
      (Item as TView).RecalcInVisible;
  end;
end;

procedure TView.SetAdjustViewBounds(const Value: Boolean);
begin
  if FAdjustViewBounds <> Value then begin
    FAdjustViewBounds := Value;
    HandleSizeChanged;
  end;
end;

procedure TView.SetBackground(const Value: TBitmap);
begin
  Background.SetBitmap(TViewState.None, Value);
end;

procedure TView.SetBackground(const Value: TBrushBitmap);
begin
  Background.SetBitmap(TViewState.None, Value);
end;

procedure TView.SetBackgroundBase(const Value: TDrawable);
begin
  SetBackground(Value);
end;

procedure TView.SetBadgeView(const Value: IViewBadge);
begin
  if Assigned(Self) then
    FBadgeView := Value;
end;

procedure TView.SetBackground(const Value: TAlphaColor);
begin
  Background.SetColor(TViewState.None, Value);
end;

procedure TView.SetBackground(const Value: TGradient);
begin
  Background.SetGradient(TViewState.None, Value);
end;

procedure TView.SetBackground(const Value: TDrawable);
begin
  if (not Assigned(FBackground)) and (Assigned(Value)) then
    FBackground := CreateBackground();
  if Assigned(FBackground) then
    FBackground.SetDrawable(Value);
end;

procedure TView.SetCaptureDragForm(const Value: Boolean);
begin
  {$IFDEF MSWINDOWS}
  FCaptureDragForm := Value;
  {$ELSE}
  {$ENDIF}
end;

procedure TView.SetClickable(const Value: Boolean);
begin
  HitTest := Value;
end;

procedure TView.SetDisableMouseWheel(const Value: Boolean);
begin
  if FDisableMouseWheel <> Value then begin
    FDisableMouseWheel := Value;
  end;
end;

procedure TView.SetGravity(const Value: TLayoutGravity);
begin
  if FGravity <> Value then begin
    FGravity := Value;
    DoGravity();
  end;
end;

procedure TView.SetHeightSize(const Value: TViewSize);
begin
  if Value <> FHeightSize then begin
    FHeightSize := Value;
    DoLayoutChanged(Self);
  end;
end;

procedure TView.SetInVisible(const Value: Boolean);
begin
  if FInVisible <> Value then begin
    FInVisible := Value;
    DoInVisibleChange;
    if Visible then
      Repaint;
  end;
end;

procedure TView.SetIsChecked(const Value: Boolean);
begin
  if Value <> GetIsChecked then begin
    if Value then
      IncViewState(TViewState.Checked)
    else
      DecViewState(TViewState.Checked);
    DoCheckedChange();
    Invalidate;
  end;
end;

procedure TView.SetLayout(const Value: TViewLayout);
begin
  if not AllowUseLayout then
    Exit;
  if (not Assigned(FLayout)) and (Assigned(Value)) then begin
    FLayout := TViewLayout.Create(Self);
    FLayout.OnChanged := DoLayoutChanged;
  end;
  if Assigned(FLayout) then
    FLayout.Assign(Value);
end;

procedure TView.SetMargin(const Value: string);
var V: Single;
begin
  if Assigned(Margins) and GetFloatValue(Value, V) then
    Margins.Rect := RectF(V, V, V, V);
end;

procedure TView.SetMaxHeight(const Value: Single);
begin
  if FMaxHeight <> Value then begin
    FMaxHeight := Value;
    DoMaxSizeChange();
  end;
end;

procedure TView.SetMaxWidth(const Value: Single);
begin
  if FMaxWidth <> Value then begin
    FMaxWidth := Value;
    DoMaxSizeChange();
  end;
end;

procedure TView.SetMinHeight(const Value: Single);
begin
  if FMinHeight <> Value then begin
    FMinHeight := Value;
    DoMinSizeChange();
  end;
end;

procedure TView.SetMinWidth(const Value: Single);
begin
  if FMinWidth <> Value then begin
    FMinWidth := Value;
    DoMinSizeChange();
  end;
end;

procedure TView.SetOrientation(const Value: TOrientation);
begin
  if FOrientation <> Value then begin  
    FOrientation := Value;
    DoOrientation();
  end;
end;

procedure TView.SetPaddings(const Value: string);
var 
  V: Single; 
begin
  if Assigned(Padding) and GetFloatValue(Value, V) then
    Padding.Rect := RectF(V, V, V, V);
end;

procedure TView.SetScrollbar(const Value: TViewScroll);
begin
  if FScrollbar <> Value then begin
    FScrollbar := Value;
    if FScrollbar = TViewScroll.None then
      FreeScrollbar
    else
      InitScrollbar;
    Repaint;
  end;
end;

procedure TView.SetTempMaxHeight(const Value: Single);
begin
  if FMaxHeight <> Value then begin
    if Value > 0 then begin
      FSaveMaxHeight := FMaxHeight;
      FMaxHeight := Value;
      DoMaxSizeChange();
    end else begin
      FMaxHeight := FSaveMaxHeight;
      FSaveMaxHeight := 0;
    end;
  end;
end;

procedure TView.SetTempMaxWidth(const Value: Single);
begin
  if FMaxWidth <> Value then begin
    if Value > 0 then begin
      FSaveMaxWidth := FMaxWidth;
      FMaxWidth := Value;
      DoMaxSizeChange()
    end else begin
      FMaxWidth := FSaveMaxWidth;
      FSaveMaxWidth := 0;
    end;
  end;
end;

procedure TView.SetViewStates(const Value: TViewStates);
begin
  FViewState := Value;
end;

procedure TView.SetWeight(const Value: Single);
begin
  if FWeight <> Value then begin
    FWeight := Value;
    DoWeight;
  end;
end;

procedure TView.SetWidthSize(const Value: TViewSize);
begin
  if Value <> FWidthSize then begin
    FWidthSize := Value;
    DoLayoutChanged(Self);
  end;
end;

procedure TView.StartScrolling;
begin
  if Scene <> nil then
    Scene.ChangeScrollingState(Self, True);
end;

procedure TView.StartTriggerAnimation(const AInstance: TFmxObject;
  const ATrigger: string);
begin
  DisableDisappear := True;
  try
    inherited;
  finally
    DisableDisappear := False;
  end;
end;

procedure TView.StartTriggerAnimationWait(const AInstance: TFmxObject;
  const ATrigger: string);
begin
  DisableDisappear := True;
  try
    inherited;
  finally
    DisableDisappear := False;
  end;
end;

procedure TView.StartWindowDrag;
var
  F: TCustomForm;
begin
  F := ParentForm;
  if Assigned(F) then
    F.StartWindowDrag;
end;

procedure TView.StopScrolling;
begin
  if Scene <> nil then
    Scene.ChangeScrollingState(nil, False);
end;

procedure TView.UpdateHScrollBar(const Value, ViewportSize: Double);
var
  AScroll: TScrollBar;
begin
  AScroll := HScrollBar;
  if AScroll <> nil then
  begin
    AScroll.ValueRange.BeginUpdate;
    try
      DoSetScrollBarValue(AScroll, Value, ViewportSize);
    finally
      AScroll.ValueRange.EndUpdate;
    end;
    AScroll.SmallChange := AScroll.ViewportSizeD / GetScrollSmallChangeFraction;
  end;
end;

procedure TView.UpdateVScrollBar(const Value, ViewportSize: Double);
var
  AScroll: TScrollBar;
begin
  AScroll := VScrollBar;
  if AScroll <> nil then
  begin
    AScroll.ValueRange.BeginUpdate;
    try
      DoSetScrollBarValue(AScroll, Value, ViewportSize);
    finally
      AScroll.ValueRange.EndUpdate;
    end;
    AScroll.SmallChange := AScroll.ViewportSizeD / GetScrollSmallChangeFraction;
  end;
end;

procedure TView.VisibleChanged;
begin
  inherited VisibleChanged;
  HandleSizeChanged;
end;

{ TViewGroup }

function TViewGroup.AddView(View: TView): Integer;
begin
  Result := Controls.Add(View);
end;

constructor TViewGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetAcceptsControls(True);
end;

destructor TViewGroup.Destroy;
begin
  inherited Destroy;
end;

procedure TViewGroup.DoAddObject(const AObject: TFmxObject);
begin
  inherited DoAddObject(AObject);
  Realign;
end;

procedure TViewGroup.DoGravity;
begin
  //inherited DoGravity;
  Realign;
end;

procedure TViewGroup.DoLayoutChanged(Sender: TObject);
begin
  inherited DoLayoutChanged(Sender);
  Realign;
end;

procedure TViewGroup.DoMaxSizeChange;
begin
  inherited DoMaxSizeChange;
  if not Assigned(ParentView) then
    Realign;
end;

procedure TViewGroup.DoMinSizeChange;
begin
  inherited DoMinSizeChange;
  if not Assigned(ParentView) then
    Realign;
end;

// �˴����Զ�������С��������ڸ������Բ�������෴������ԣ�Ҳ���������Բ�����
// �Ƿ�Ҫ��������Ŀ�Ȼ�߶�
function TViewGroup.IsAdjustSize(View: IView; Align: TAlignLayout;
  AParentOrientation: TOrientation): Boolean;
begin
  if Assigned(View) then begin
    // ʵ���� IView �ӿ�
    if AParentOrientation = TOrientation.Horizontal then
      // ���������Բ������Ϊˮƽ����ʱ���߶��游������Ҫ�����߶�
      Result := (View.GetHeightSize = TViewSize.FillParent)
    else
      // ���������Բ������Ϊ��ֱ����ʱ���ж��Ƿ���Ҫ�������
      Result := (View.GetWidthSize = TViewSize.FillParent);
  end else if (Align = TAlignLayout.None) or (Align = TAlignLayout.Scale) then
    // Align ���������С
    Result := False
  else if AParentOrientation = TOrientation.Horizontal then
    // ��Щ Align ֵ��Ҫ��������߶�
    Result := Align in [TAlignLayout.Left, TAlignLayout.Right,
      TAlignLayout.MostLeft, TAlignLayout.MostRight,
      TAlignLayout.Client, TAlignLayout.Contents,
      TAlignLayout.HorzCenter, TAlignLayout.Vertical, TAlignLayout.Fit,
      TAlignLayout.FitLeft, TAlignLayout.FitRight]
  else
    // ��Щ Align ֵ��Ҫ����������
    Result := Align in [TAlignLayout.Top, TAlignLayout.Bottom,
      TAlignLayout.MostTop, TAlignLayout.MostBottom,
      TAlignLayout.Client, TAlignLayout.Contents,
      TAlignLayout.VertCenter, TAlignLayout.Horizontal, TAlignLayout.Fit,
      TAlignLayout.FitLeft, TAlignLayout.FitRight];
end;

procedure TViewGroup.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DoRealign;
end;

function TViewGroup.RemoveView(View: TView): Integer;
begin
  Result := Controls.Remove(View);
end;

procedure TViewGroup.Resize;
begin
  if csReading in ComponentState then
    Exit;
  inherited Resize;
  Realign;
end;

{ TLinearLayout }

procedure TLinearLayout.DoOrientation;
begin
  Realign;
end;

procedure TLinearLayout.DoRealign;
var
  CtrlCount: Integer;
  I: Integer;
  WeightSum: Double;
  LIsAdjustSize: Boolean;
  CurPos: TPointD;
  W, H, Fix: Single;
  VL, VT, VW, VH: Double;
  MaxW, MaxH: Double;
  Control: TControl;
  ReSizeView: TView;
  View: IView;
  SaveAdjustViewBounds, LAutoSize: Boolean;
  LAdjustControl: TControl;
  LAdjustSize: Single;
  IsWeight: Boolean;
begin
  if FDisableAlign then
    Exit;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  //LogD(Self.ClassName + '.DoRealign.');

  FDisableAlign := True;

  // �õ�������������߿�
  MaxW := GetParentMaxWidth;
  MaxH := GetParentMaxHeight;

  // �õ�������Ŀ�ʼ����
  CurPos := TPointD.Create(Padding.Left, Padding.Top);
  W := Width - CurPos.X - Padding.Right;
  H := Height - CurPos.Y - Padding.Bottom;
  CtrlCount := ControlsCount;

  // ������� > 0 ���ӿؼ� > 0 ʱ�Ŵ�����
  if ((W > 0) and (H > 0)) or (CtrlCount > 0) then begin
    // ��ȡ�����������������С֮��
    WeightSum := GetWeightSum(Fix);
    IsWeight := WeightSum > 0;
    // ��� WeightSum ����0��˵��ʹ��������, �򲻽�������Զ���С������
    LIsAdjustSize := (WeightSum <= 0) and AdjustAutoSizeControl(LAdjustControl, LAdjustSize);

    // ���û���Զ�����ָ�������ϵĴ�С��������������Զ���������Ŀ�ʼλ��
    if (not LIsAdjustSize) then begin
      if Orientation = TOrientation.Horizontal then begin
        // ˮƽ����
        if FGravity in [TLayoutGravity.CenterHorizontal, TLayoutGravity.CenterHBottom, TLayoutGravity.Center] then
          // ˮƽ����
          CurPos.X := (W - Fix) / 2 + Padding.Left
        else if FGravity in [TLayoutGravity.RightTop, TLayoutGravity.RightBottom, TLayoutGravity.CenterVRight] then
          // �ұ�
          CurPos.X := W - Fix + Padding.Left;
      end else begin
        // ��ֱ����
        if FGravity in [TLayoutGravity.CenterVertical, TLayoutGravity.CenterVRight, TLayoutGravity.Center] then
          // ��ֱ����
          CurPos.Y := (H - Fix) / 2 + Padding.Top
        else if FGravity in [TLayoutGravity.LeftBottom, TLayoutGravity.RightBottom, TLayoutGravity.CenterHBottom] then
          // �ױ�
          CurPos.Y := H - Fix + Padding.Top;
      end;
    end;

    for I := 0 to CtrlCount - 1 do begin
      Control := Controls[I];
      {$IFDEF MSWINDOWS}
      // ��������״̬������� DesignerControl ʱ����
      if (csDesigning in ComponentState) then begin
        if Supports(Control, IDesignerControl) then
          Continue;
        if IsDesignerControl(Control) then
          Continue;
      end;
      {$ENDIF}
      if not Control.Visible then Continue;

      // �õ����IView�ӿڣ����Ƿ����������С��С����
      View := nil;
      if (Supports(Control, IView, View)) then begin
        SaveAdjustViewBounds := View.GetAdjustViewBounds;
      end else
        SaveAdjustViewBounds := False;

      // �ж��������һ�������Ƿ���Ҫ�Զ���С
      LAutoSize := IsAdjustSize(View, Control.Align, FOrientation);

      // ˮƽ����
      if FOrientation = TOrientation.Horizontal then begin
        // ���� Left
        VL := CurPos.X + Control.Margins.Left;

        // ������
        if Assigned(View) and (WeightSum > 0) and (View.GetWeight > 0) then begin
          // ���ʹ�����������������������
          VW := (W - Fix) / WeightSum * View.GetWeight - Control.Margins.Left - Control.Margins.Right;
        end else if Control = LAdjustControl then begin
          // �������Ҫ�Զ�������С�����
          VW := LAdjustSize - Control.Margins.Right - Control.Margins.Left;
        end else
          VW := Control.Width;

        // ����ȴ�С����
        if SaveAdjustViewBounds then begin
          if (View.GetMaxWidth > 0) and (VW > View.GetMaxWidth) then
            VW := View.GetMaxWidth;
          if (View.GetMinWidth > 0) and (VW < View.GetMinWidth) then
            VW := View.GetMinWidth;
        end;

        if LAutoSize then begin
          // �Զ��߶�
          VT := CurPos.Y + Control.Margins.Top;
          VH :=  H - VT - Control.Margins.Bottom + Padding.Top;

          // ���߶ȴ�С����
          if SaveAdjustViewBounds then begin
            if (View.GetMaxHeight > 0) and (VH > View.GetMaxHeight) then
              VH := View.GetMaxHeight;
            if (View.GetMinHeight > 0) and (VH < View.GetMinHeight) then
              VH := View.GetMinHeight;
          end;
        end else begin
          VH := Control.Height;

          // ���߶ȴ�С����
          if SaveAdjustViewBounds then begin
            if (View.GetMaxHeight > 0) and (VH > View.GetMaxHeight) then
              VH := View.GetMaxHeight;
            if (View.GetMinHeight > 0) and (VH < View.GetMinHeight) then
              VH := View.GetMinHeight;
          end;

          // ���Զ��߶�ʱ������������������λ��
          case FGravity of
            TLayoutGravity.LeftTop, TLayoutGravity.RightTop:
              // ����
              VT := CurPos.Y + Control.Margins.Top;
            TLayoutGravity.LeftBottom, TLayoutGravity.RightBottom, TLayoutGravity.CenterHBottom:
              // �ײ�
              VT := H - VH - Control.Margins.Bottom + Padding.Top;
            TLayoutGravity.CenterVertical, TLayoutGravity.Center, TLayoutGravity.CenterVRight:
              // ����
              VT := (H - (VH + Control.Margins.Top + Control.Margins.Bottom)) / 2 + Padding.Top + Control.Margins.Top;
          else
            begin
              if Align in [TAlignLayout.None, TAlignLayout.Scale] then
                // �Զ���λ��
                VT := Control.Position.Y
              else
                // ʹ�� Align ���ԣ�Ĭ�����Ͻ�
                VT := CurPos.Y + Control.Margins.Top;
            end;
          end;
        end;

        // ���� Align ���������������λ��
        if not LAutoSize then begin
          case Control.Align of
            TAlignLayout.Bottom, TAlignLayout.MostBottom:
              VT := H - VH - Control.Margins.Bottom + Padding.Top;
            TAlignLayout.Center, TAlignLayout.VertCenter:
              VT := (H - VH) / 2 + Padding.Top;
          end;
        end;

        // ������������
        if Assigned(View) and (View.GetWeight > 0) then begin
          Fix := Fix + VW + Control.Margins.Left + Control.Margins.Right;
          WeightSum := WeightSum - View.GetWeight;
        end;

      // ��ֱ����
      end else begin

        // ���� Top
        VT := CurPos.Y + Control.Margins.Top;
        // ����߶�
        if Assigned(View) and (WeightSum > 0) and (View.GetWeight > 0) then begin
          // ���ʹ�����������������������
          VH := (H - Fix) / WeightSum * View.GetWeight - Control.Margins.Top - Control.Margins.Bottom;
        end else if Control = LAdjustControl then begin
          // �������Ҫ�Զ�������С�����
          VH := LAdjustSize - Control.Margins.Bottom - Control.Margins.Top;
        end else
          VH := Control.Height;

        // ���߶ȴ�С����
        if SaveAdjustViewBounds then begin
          if (View.GetMaxHeight > 0) and (VH > View.GetMaxHeight) then
            VH := View.GetMaxHeight;
          if (View.GetMinHeight > 0) and (VH < View.GetMinHeight) then
            VH := View.GetMinHeight;
        end;

        if LAutoSize then begin
          // �Զ����
          VL := CurPos.X + Control.Margins.Left;
          VW := W - VL - Control.Margins.Right + Padding.Left;

          // ����ȴ�С����
          if SaveAdjustViewBounds then begin
            if (View.GetMaxWidth > 0) and (VW > View.GetMaxWidth) then
              VW := View.GetMaxWidth;
            if (View.GetMinWidth > 0) and (VW < View.GetMinWidth) then
              VW := View.GetMinWidth;
          end;
        end else begin
          VW := Control.Width;

          // ����ȴ�С����
          if SaveAdjustViewBounds then begin
            if (View.GetMaxWidth > 0) and (VW > View.GetMaxWidth) then
              VW := View.GetMaxWidth;
            if (View.GetMinWidth > 0) and (VW < View.GetMinWidth) then
              VW := View.GetMinWidth;
          end;

          // ���Զ����ʱ������������������λ��
          case FGravity of
            TLayoutGravity.LeftTop, TLayoutGravity.LeftBottom:
              // ���
              VL := CurPos.X + Control.Margins.Left;
            TLayoutGravity.RightTop, TLayoutGravity.RightBottom, TLayoutGravity.CenterVRight:
              // �ұ�
              VL := W - VW - Control.Margins.Right + Padding.Left;
            TLayoutGravity.CenterHBottom, TLayoutGravity.Center:
              // �м�
              VL := (W - (VW + Control.Margins.Left + Control.Margins.Right)) / 2 + Padding.Left + Control.Margins.Left;
          else
            begin
              if Align in [TAlignLayout.None, TAlignLayout.Scale] then
                // �Զ���λ��
                VL := Control.Position.X
              else
                // ʹ�� Align ���ԣ�Ĭ�����Ͻ�
                VL := CurPos.X + Control.Margins.Left;
            end;
          end;
        end;

        // ���� Align ���������������λ��
        if not LAutoSize then begin
          case Control.Align of
            TAlignLayout.Right, TAlignLayout.MostRight:
              VL := W - VW - Control.Margins.Right + Padding.Left;
            TAlignLayout.Center, TAlignLayout.HorzCenter:
              VL := (W - VW) / 2 + Padding.Left;
          end;
        end;

        // ������������
        if Assigned(View) and (View.GetWeight > 0) then begin
          Fix := Fix + VH + Control.Margins.Top + Control.Margins.Bottom;
          WeightSum := WeightSum - View.GetWeight;
        end;
      end;

      // ���������С
      if Assigned(View) then begin
        Control.SetBounds(VL, VT, VW, VH);
        //SetAdjustViewBounds(SaveAdjustViewBounds);
      end else
        Control.SetBounds(VL, VT, VW, VH);

      // ���¼���Fix����������������ʵ��СΪ׼
      if FOrientation = TOrientation.Horizontal then
        Fix := Fix + Control.Width - VW
      else
        Fix := Fix + Control.Height - VH;

      // ���µ�ǰ����
      if FOrientation = TOrientation.Horizontal then begin
        CurPos.X := VL + Control.Width + Control.Margins.Right;
      end else
        CurPos.Y := VT + Control.Height + Control.Margins.Bottom;
    end;

    // �ж��Ƿ������СΪ�����ݡ�����ǣ��������ݴ�С������С
    if Orientation = TOrientation.Horizontal then begin
      VW := CurPos.X + Padding.Right;
      VH := Height;

      // �߶ȳ�������
      if (VW > MaxW) and (MaxW > 0) then begin
        // ���ʹ���� Weight
        if IsWeight then begin
          // ��ȡ���ʹ�� Weight ���Ե���������µ�����С
          ReSizeView := GetLastWeightView();
          if Assigned(ReSizeView) then begin
            ReSizeView.TempMaxWidth := ReSizeView.Width - (VW - MaxW);
            ReSizeView.Width := ReSizeView.TempMaxWidth;
          end;
        end;
        VW := MaxW;
      end;

      if (WidthSize = TViewSize.WrapContent) and (Width <> VW) then
        SetBounds(Left, Top, VW, VH);

    end else begin
      VW := Width;
      VH := CurPos.Y + Padding.Bottom;

      // �߶ȳ�������
      if (VH > MaxH) and (MaxH > 0) then begin
        // ���ʹ���� Weight
        if IsWeight then begin
          // ��ȡ���ʹ�� Weight ���Ե���������µ�����С
          ReSizeView := GetLastWeightView();
          if Assigned(ReSizeView) then begin
            ReSizeView.TempMaxHeight := ReSizeView.Height - (VH - MaxH);
            ReSizeView.Height := ReSizeView.TempMaxHeight;
          end;
        end;
        VH := MaxH;
      end;

      if (HeightSize = TViewSize.WrapContent) and (Height <> VH) then
        SetBounds(Left, Top, VW, VH);

    end;

  end else
    inherited DoRealign;
  FDisableAlign := False;
  //LogD(Self.ClassName + '.DoRealign OK.');
end;

procedure TLinearLayout.DoRecalcSize(var AWidth, AHeight: Single);
var
  I: Integer;
  P, Control: TControl;
  IsAW, IsAH, IsASW, IsASH: Boolean;
  V: Single;
begin
  //if IsUpdating or (csDestroying in ComponentState) then
  if (csDestroying in ComponentState) or (csLoading in ComponentState) then
    Exit;
  if not Assigned(ParentView) then begin
    P := ParentControl;
    IsAW := False;
    IsAH := False;

    // ��ˮƽ���Ƿ��Զ���С
    IsASW := IsAdjustSize(nil, Align, TOrientation.Vertical);
    // �ڴ�ֱ���Ƿ��Զ���С
    IsASH := IsAdjustSize(nil, Align, TOrientation.Horizontal);

    // ˮƽ����
    if (FOrientation = TOrientation.Horizontal) and (not IsASW) then begin
      if WidthSize = TViewSize.WrapContent then begin
        AWidth := Padding.Left + Padding.Right;
        IsAW := True;
      end else if WidthSize = TViewSize.FillParent then begin
        if Assigned(P) then
          AWidth := P.Width - P.Padding.Left - P.Padding.Right - Margins.Left - Margins.Right
        else
          AWidth := Padding.Left + Padding.Right;
      end;
    end else begin
      IsASW := ((WidthSize = TViewSize.WrapContent) and (FOrientation = TOrientation.Vertical));
      if IsASW then
        AWidth := 0;
    end;

    // ��ֱ����
    if (FOrientation = TOrientation.Vertical) and (not IsASH) then begin
      if HeightSize = TViewSize.WrapContent then begin
        AHeight := Padding.Top + Padding.Bottom;
        IsAH := True;
      end else if HeightSize = TViewSize.FillParent then begin
        if Assigned(P) then
          AHeight := P.Height - P.Padding.Top - P.Padding.Bottom - Margins.Top - Margins.Bottom
        else
          AHeight := Padding.Top + Padding.Bottom;
      end
    end else begin
      IsASH := ((HeightSize = TViewSize.WrapContent)) and (FOrientation = TOrientation.Horizontal);
      if IsASH then
        AHeight := 0;
    end;

    // �������Ҫ�Զ���С�ģ����ӿؼ���С������
    if IsAW or IsAH or IsASW or IsASH then begin
      for I := 0 to ControlsCount - 1 do begin
        Control := Controls[I];
        if not Control.Visible then Continue;
        {$IFDEF MSWINDOWS}
        if IsDesignerControl(Control) then Continue;
        {$ENDIF}

        if IsAW then
          AWidth := AWidth + Control.Width + Control.Margins.Left + Control.Margins.Right
        else if IsASW then begin
          V := Control.Position.X + Control.Width + Control.Margins.Right;
          if V > AWidth then
            AWidth := V;
        end;

        if IsAH then
          AHeight := AHeight + Control.Height + Control.Margins.Top + Control.Margins.Bottom
        else if IsASH then begin
          V := Control.Position.Y + Control.Height + Control.Margins.Bottom;
          if V > AHeight then
            AHeight := V;
        end;
      end;

      if IsASW then AWidth := AWidth + Padding.Left + Padding.Right;
      if IsASH then AHeight := AHeight + Padding.Top + Padding.Bottom;

    end;

  end else begin

    if FDisableAlign then
      Exit;

    // ��ˮƽ���Ƿ��Զ���С
    IsASW := IsAdjustSize(Self, Align, TOrientation.Vertical);
    // �ڴ�ֱ���Ƿ��Զ���С
    IsASH := IsAdjustSize(Self, Align, TOrientation.Horizontal);

    IsAW := (WidthSize = TViewSize.WrapContent) and (not IsASW);
    IsAH := (HeightSize = TViewSize.WrapContent) and (not IsASH);

    if IsAW then AWidth := 0;
    if IsAH then AHeight := 0;

    // �������Ҫ�Զ���С�ģ����ӿؼ���С������
    if IsAW or IsAH then begin
      for I := 0 to ControlsCount - 1 do begin
        Control := Controls[I];
        if not Control.Visible then Continue;
        {$IFDEF MSWINDOWS}
        if IsDesignerControl(Control) then Continue;
        {$ENDIF}
        
        if IsAW then begin
          V := Control.Position.X + Control.Width + Control.Margins.Right;
          if V > AWidth then
            AWidth := V;
        end;
        if IsAH then begin
          V := Control.Position.Y + Control.Height + Control.Margins.Bottom;
          if V > AHeight then
            AHeight := V;
        end;
      end;

      if IsAW then AWidth := AWidth + Padding.Left + Padding.Right;
      if IsAH then AHeight := AHeight + Padding.Top + Padding.Bottom;
    end;
  end;
end;

function TLinearLayout.AdjustAutoSizeControl(out AControl: TControl;
  out AdjustSize: Single): Boolean;
var
  I: Integer;
  Control: TControl;
  View: IView;
  AO, FO: TOrientation;
  NewSize: Single;
begin
  Result := False;
  AControl := nil;
  AdjustSize := 0;
  NewSize := 0;

  // �õ�һ���෴�Ĳ��ַ��棬���� IsAutoSize
  FO := FOrientation;
  if FO = TOrientation.Horizontal then
    AO := TOrientation.Vertical
  else
    AO := TOrientation.Horizontal;

  for I := ControlsCount - 1 downto 0 do begin
    Control := Controls[I];
    if not Control.Visible then Continue;
    {$IFDEF MSWINDOWS}
    if IsDesignerControl(Control) then Continue;
    {$ENDIF}
    
    // �����û���ҵ���Ҫ�Զ���С�����������м��
    if (AControl = nil) then begin
      View := nil;
      Supports(Control, IView, View);
      if (IsAdjustSize(View, Control.Align, AO)) then begin
        AControl := Control;
        Continue;
      end;
    end;
    //  �ۼӷ��Զ���С�ؼ��Ĵ�С
    if FO = TOrientation.Horizontal then
      NewSize := NewSize + Control.Margins.Left + Control.Width + Control.Margins.Right
    else
      NewSize := NewSize + Control.Margins.Top + Control.Height + Control.Margins.Bottom;
  end;

  // �����������Ҫ�Զ���С���������������С
  if AControl <> nil then begin
    Result := True;
    if FO = TOrientation.Horizontal then
      AdjustSize := FSize.Width - Padding.Left - Padding.Right - NewSize
    else
      AdjustSize := FSize.Height - Padding.Top - Padding.Bottom - NewSize
  end;
end;

function TLinearLayout.GetLastWeightView: TView;
var
  I: Integer;
  Control: TControl;
  View: IView;
begin
  Result := nil;
  for I := ControlsCount - 1 downto 0 do begin
    Control := Controls[I];
    if (not Control.Visible) then Continue;
    if (Supports(Control, IView, View)) and (View.GetWeight > 0) then begin
      Result := Control as TView;
      Break;
    end
  end;
end;

function TLinearLayout.GetWeightSum(var FixSize: Single): Single;
var
  I: Integer;
  Control: TControl;
  View: IView;
begin
  Result := 0;
  FixSize := 0;
  for I := 0 to ControlsCount - 1 do begin
    Control := Controls[I];
    if (not Control.Visible) then Continue;
    {$IFDEF MSWINDOWS}
    if IsDesignerControl(Control) then Continue;
    {$ENDIF}
    if (Supports(Control, IView, View)) and (View.GetWeight > 0) then
      Result := Result + View.GetWeight
    else begin
      if FOrientation = TOrientation.Horizontal then
        FixSize := FixSize + Control.Width + Control.Margins.Left + Control.Margins.Right
      else
        FixSize := FixSize + Control.Height + Control.Margins.Top + Control.Margins.Bottom;
    end;
  end;
end;

function TLinearLayout.IsUseWeight: Boolean;
var V: Single;
begin
  Result := GetWeightSum(V) > 0;
end;

{ TRelativeLayout }

constructor TRelativeLayout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FViewList := TList<TControl>.Create;
end;

destructor TRelativeLayout.Destroy;
begin
  FreeAndNil(FViewList);
  inherited;
end;

procedure TRelativeLayout.DoAlignControl(const X, Y, W, H: Single);
var
  R: TRectF;
  AlignList: TInterfaceList;
  ALastWidth, ALastHeight: Single;
  List: TList<TControl>;

  function InsertBefore(const C1, C2: IAlignableObject; AAlign: TAlignLayout): Boolean;
  begin
    Result := False;
    case AAlign of
      TAlignLayout.Top, TAlignLayout.MostTop:
        Result := C1.Top < C2.Top;
      TAlignLayout.Bottom, TAlignLayout.MostBottom:
        Result := (C1.Top + C1.Height) >= (C2.Top + C2.Height);
      TAlignLayout.Left, TAlignLayout.MostLeft:
        Result := C1.Left < C2.Left;
      TAlignLayout.Right, TAlignLayout.MostRight:
        Result := (C1.Left + C1.Width) >= (C2.Left + C2.Width);
    end;
  end;

  procedure DoAlign(List: TList<TControl>; AAlign: TAlignLayout);
  var
    I, J: Integer;
    Control: TControl;
    LControl: IAlignableObject;
    ALCount: Integer;
  begin
    AlignList.Clear;
    for I := 0 to List.Count - 1 do begin
      Control := TControl(List.Items[I]);
      if not Supports(Control, IAlignableObject, LControl) then
        Continue;
      if (AAlign = TALignLayout.None) and (csLoading in Control.ComponentState) then
        Continue;
      if (LControl.Align = AAlign) and (LControl.AllowAlign) then
      begin
        J := 0;
        ALCount := AlignList.Count;
        while (J < ALCount) and (AAlign <> TAlignLayout.None) and not InsertBefore(LControl, IAlignableObject(AlignList[J]), AAlign) do
          Inc(J);
        AlignList.Insert(J, LControl);
      end;
    end;
    ALCount := AlignList.Count;
    for I := 0 to ALCount - 1 do begin
      ArrangeControl(IAlignableObject(AlignList[I]), AAlign, W, H, ALastWidth, ALastHeight, R);
    end;
  end;

  procedure DoGetList(const List: TList<TControl>);
  var
    View: IView;
    Control: TControl;
    I: Integer;
  begin
    List.Clear;
    for I := 0 to ControlsCount - 1 do begin
      Control := Controls[I];
      if not Control.Visible then Continue;
      {$IFDEF MSWINDOWS}
      if (csDesigning in ComponentState)
        and Supports(Control, IDesignerControl) then Continue;
      {$ENDIF}

      if (Supports(Control, IView, View)) then begin
        if (Assigned(View.GetLayout)) then begin
          FViewList.Add(Control);
          Continue;
        end;
      end;

      if (Control.Align = TALignLayout.None) or (csLoading in Control.ComponentState) then
        Continue;

      List.Add(Control);
    end;
  end;

begin
  if (csDestroying in ComponentState) or (W < 1) or (H < 1) then
    Exit;
  AlignList := TInterfaceList.Create;
  ALastWidth := W;
  ALastHeight := H;
  R := RectF(0, 0, W, H);
  R := Padding.PaddingRect(R);
  List := TList<TControl>.Create;
  try
    DoGetList(List);
    // Align
    DoAlign(List, TAlignLayout.MostTop);
    DoAlign(List, TAlignLayout.MostBottom);
    DoAlign(List, TAlignLayout.MostLeft);
    DoAlign(List, TAlignLayout.MostRight);
    DoAlign(List, TAlignLayout.Top);
    DoAlign(List, TAlignLayout.Bottom);
    DoAlign(List, TAlignLayout.Left);
    DoAlign(List, TAlignLayout.Right);
    DoAlign(List, TAlignLayout.FitLeft);
    DoAlign(List, TAlignLayout.FitRight);
    DoAlign(List, TAlignLayout.Client);
    DoAlign(List, TAlignLayout.Horizontal);
    DoAlign(List, TAlignLayout.Vertical);
    DoAlign(List, TAlignLayout.Contents);
    DoAlign(List, TAlignLayout.Center);
    DoAlign(List, TAlignLayout.HorzCenter);
    DoAlign(List, TAlignLayout.VertCenter);
    DoAlign(List, TAlignLayout.Scale);
    DoAlign(List, TAlignLayout.Fit);
    // Anchors
    DoAlign(List, TAlignLayout.None);
    FLastWidth := W;
    FLastHeight := H;
  finally
    AlignList.Free;
    List.Free;
  end;
end;

procedure TRelativeLayout.DoRealign;
var
  List: TList<TControl>;
  W, H: Single;
  I: Integer;
  CurPos: TPointF;
  VL, VT, VW, VH: Single;
  View: TControl;
  LView: IView;
  //SaveAdjustViewBounds: Boolean;
begin
  if FDisableAlign or (not Assigned(FViewList)) then
    Exit;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  FDisableAlign := True;
  CurPos := PointF(Padding.Left, Padding.Top);
  W := Self.Width - CurPos.X - Padding.Right;
  H := Self.Height - CurPos.Y - Padding.Bottom;

  if (W > 0) and (H > 0) then begin
    FViewList.Clear;
    DoAlignControl(CurPos.X, CurPos.Y, FSize.Width, FSize.Height);
    //SaveAdjustViewBounds := False;
    List := TList<TControl>.Create;
    try
      for I := 0 to FViewList.Count - 1 do begin
        View := FViewList[I];
        if not Supports(View, IView, LView) then Continue;

        List.Clear;
        if GetXY(List, View, VL, VT, VW, VH) < 0 then Exit;
        VL := VL + View.Margins.Left;
        VT := VT + View.Margins.Top;
        VW := VW - View.Margins.Left - View.Margins.Right;
        VH := VH - View.Margins.Top - View.Margins.Bottom;
        //LView.SetAdjustViewBounds(False);
        View.SetBounds(VL, VT, VW, VH);
        //LView.SetAdjustViewBounds(SaveAdjustViewBounds);
      end;
    finally
      List.Free;
    end;
  end;
  FDisableAlign := False;
end;

procedure TRelativeLayout.DoRecalcSize(var AWidth, AHeight: Single);
var
  I: Integer;
  Control: TControl;
  IsAW, IsAH: Boolean;
  V: Single;
begin
  if IsUpdating or (csDestroying in ComponentState) then
    Exit;

  IsAW := (WidthSize = TViewSize.WrapContent) and
    (not IsAdjustSize(nil, Align, TOrientation.Vertical));
  IsAH := (HeightSize = TViewSize.WrapContent) and
    (not IsAdjustSize(nil, Align, TOrientation.Horizontal));

  // �������Ҫ�Զ���С�ģ����ӿؼ���С������
  if IsAW or IsAH then begin

    if IsAW then AWidth := 0;
    if IsAH then AHeight := 0;

    for I := 0 to ChildrenCount - 1 do begin
      Control := Controls[I];
      if not Control.Visible then Continue;
      {$IFDEF MSWINDOWS}
      if IsDesignerControl(Control) then Continue;
      {$ENDIF}
      
      if IsAW then begin
        V := Control.Width + Control.Position.X + Control.Margins.Right + Padding.Right;
        if V > AWidth then
          AWidth := V;
      end;
      if IsAH then begin
        V := Control.Height + Control.Position.Y + Control.Margins.Bottom + Padding.Bottom;
        if V > AHeight then
          AHeight := V;
      end;
    end;
  end;
end;

procedure TRelativeLayout.DoRemoveObject(const AObject: TFmxObject);

  procedure RemoveLink(var Data: TControl);
  begin
    if Data = AObject then
      Data := nil;
  end;

var
  I: Integer;
  Item: TControl;
  View: IView;
  Layout: TViewLayout;
begin
  if not (csDestroying in ComponentState) then begin
    // ɾ������ʱ������������õ����ĵط�
    for I := 0 to ControlsCount - 1 do begin
      Item := Controls[I];
      if Supports(Item, IView, View) then begin
        Layout := View.Layout;
        if Layout = nil then Continue;
        RemoveLink(Layout.FToLeftOf);
        RemoveLink(Layout.FToRightOf);
        RemoveLink(Layout.FAbove);
        RemoveLink(Layout.FBelow);
        RemoveLink(Layout.FAlignBaseline);
        RemoveLink(Layout.FAlignLeft);
        RemoveLink(Layout.FAlignTop);
        RemoveLink(Layout.FAlignRight);
        RemoveLink(Layout.FAlignBottom);
      end;
    end;
  end;
  inherited DoRemoveObject(AObject);
end;

function TRelativeLayout.GetXY(const StackList: TList<TControl>; const Control: TControl;
  var X, Y, W, H: Single): Integer;
var
  View: IView;
  Layout: TViewLayout;
  PW, PH: Single;
  AX, AY, AW, AH: Single;
  BX, BY, BW, BH: Single;
  I: Integer;
  DecH, DecW, DecHD2: Boolean;
  AutoW, AutoH: Boolean;
  Parent: TControl;
begin
  Result := 1;
  if not Assigned(Control) then Exit;
  if csDestroying in Control.ComponentState then Exit;

  if Control.Visible then begin
    W := Control.Width + Control.Margins.Left + Control.Margins.Right;
    H := Control.Height + Control.Margins.Top + Control.Margins.Bottom;
  end else begin
    W := 0;
    H := 0;
  end;

  if not (Supports(Control, IView, View)) then begin
    X := Control.Position.X;
    Y := Control.Position.Y;
    Exit;
  end else begin
    X := 0;
    Y := 0;
  end;
  if (StackList.Count > 0) then begin
    if StackList.Count > 256 then begin
      Result := -1;
      Exit;
    end;
    I := StackList.IndexOf(Control);
    if (I >= 0) then begin
      Result := -2;
      Exit;
    end;
  end;
  Layout := View.Layout;
  if not Assigned(Layout) then
    Exit;
  Parent := View.ParentControl;
  if Assigned(Parent) then begin
    PW := Parent.Width - Parent.Padding.Left - Parent.Padding.Right;
    PH := Parent.Height - Parent.Padding.Top - Parent.Padding.Bottom;
  end else begin
    PW := 0; PH := 0;
  end;
  if (not Layout.AlignParentLeft) and Assigned(View.Position) then
    X := View.Position.X;
  if (not Layout.AlignParentTop) and Assigned(View.Position) then
    Y := View.Position.Y;
  StackList.Add(Control);
  try

    DecH := False;
    DecW := False;
    DecHD2 := False;

    AutoW := View.WidthSize = TViewSize.FillParent;
    AutoH := View.HeightSize = TViewSize.FillParent;

    if (Layout.FCenterInParent) or (Layout.FCenterVertical and Layout.FCenterHorizontal) then begin
      if AutoW then W := PW;
      if AutoH then H := PH;
      if Assigned(Parent) then begin
        X := Parent.Padding.Left + (PW - W) / 2;
        Y := Parent.Padding.Top + (PH - H) / 2;
      end;
      Exit;
    end;

    if Layout.FCenterVertical then begin
      if AutoH then H := PH;
      if Assigned(Parent) then
        Y := (PH - H) / 2;
    end else if Assigned(Layout.FAlignBaseline) then begin
      if AutoH then begin
        H := PH;
        Y := 0;
      end else begin
        Result := GetXY(StackList, Layout.FAlignBaseline, AX, AY, AW, AH);
        if Result < 0 then Exit;
        Y := AY + AH / 2;
        DecHD2 := True;
      end;
    end else if Assigned(Layout.FAlignTop) then begin
      Result := GetXY(StackList, Layout.FAlignTop, AX, AY, AW, AH);
      if Result < 0 then Exit;
      Y := AY + Layout.FAlignTop.Margins.Top;
      if Assigned(Layout.FAlignBottom) then begin
        Result := GetXY(StackList, Layout.FAlignBottom, BX, BY, BW, BH);
        if Result < 0 then Exit;
        H := (BY + BH + Layout.FAlignBottom.Margins.Bottom) - Y;
      end else if AutoH then
        H := PH - Y;
    end else if Assigned(Layout.FAlignBottom) then begin
      Result := GetXY(StackList, Layout.FAlignBottom, AX, AY, AW, AH);
      if Result < 0 then Exit;
      Y := AY + AH - Layout.FAlignBottom.Margins.Bottom;
      if AutoH then begin
        H := Y;
        Y := 0;
      end else
        DecH := True;
    end else if Assigned(Layout.FAbove) then begin
      Result := GetXY(StackList, Layout.FAbove, AX, AY, AW, AH);
      if Result < 0 then Exit;
      Y := AY + Layout.FAbove.Margins.Top;
      if Assigned(Layout.FBelow) then begin
        Result := GetXY(StackList, Layout.FBelow, BX, BY, BW, BH);
        if Result < 0 then Exit;
        H := Y - (BY + BH + Layout.FBelow.Margins.Bottom);
      end else begin
        if AutoH then begin
          H := Y;
          Y := 0;
        end else
          DecH := True;
      end;
    end else if Assigned(Layout.FBelow) then begin
      Result := GetXY(StackList, Layout.FBelow, BX, BY, BW, BH);
      if Result < 0 then Exit;
      Y := BY + BH + Layout.FBelow.Margins.Bottom;
      if AutoH then
        H := PH - Y;
    end else if Layout.FAlignParentTop then begin
      if Assigned(Parent) then
        Y := Parent.Padding.Top
      else
        Y := 0;
      if AutoH then H := PH;
    end else if Layout.FAlignParentBottom then begin
      if AutoH then begin
        Y := 0;
        H := PH;
      end else if Assigned(Parent) then
        Y := PH - H + Parent.Padding.Top
      else
        Y := PH - H;
    end else begin
      if AutoH then
        H := PH - Y;
    end;

    if Layout.FCenterHorizontal then begin
      if AutoW then W := PW;
      if Assigned(Parent) then
        X := Parent.Padding.Left + (PW - W) / 2;
    end else if Assigned(Layout.FAlignLeft) then begin
      Result := GetXY(StackList, Layout.FAlignLeft, AX, AY, AW, AH);
      if Result < 0 then Exit;
      X := AX - Layout.FAlignLeft.Margins.Left;
      if Assigned(Layout.FAlignRight) then begin
        Result := GetXY(StackList, Layout.FAlignRight, BX, BY, BW, BH);
        if Result < 0 then Exit;
        W := (BX + BW + Layout.FAlignRight.Margins.Right) - X;
      end else if AutoW then
        W := PW - X;
    end else if Assigned(Layout.FAlignRight) then begin
      Result := GetXY(StackList, Layout.FAlignRight, AX, AY, AW, AH);
      if Result < 0 then Exit;
      X := AX + AW + Layout.FAlignRight.Margins.Right;
      if AutoW then begin
        W := X;
        X := 0;
      end else
        DecW := True;
    end else if Assigned(Layout.FToRightOf) then begin
      Result := GetXY(StackList, Layout.FToRightOf, AX, AY, AW, AH);
      if Result < 0 then Exit;
      X := AX + AW + Layout.FToRightOf.Margins.Right;
      if Assigned(Layout.FToLeftOf) then begin
        Result := GetXY(StackList, Layout.FToLeftOf, BX, BY, BW, BH);
        if Result < 0 then Exit;
        W := (BX - Layout.FToLeftOf.Margins.Left) - X;
      end else begin
        if AutoW then
          W := PW - X;
      end;
    end else if Assigned(Layout.FToLeftOf) then begin
      Result := GetXY(StackList, Layout.FToLeftOf, AX, AY, AW, AH);
      if Result < 0 then Exit;
      X := AX; // - Layout.FToLeftOf.Margins.Left;
      if AutoW then begin
        W := X;
        X := 0;
      end else
        DecW := True;
    end else if Layout.FAlignParentLeft then begin
      if Assigned(Parent) then
        X := Parent.Padding.Left
      else
        X := 0;
      if AutoW then W := PW;
    end else if Layout.FAlignParentRight then begin
      if AutoW then begin
        X := 0;
        W := PW;
      end else if Assigned(Parent) then
        X := PW - W + Parent.Padding.Left
      else
        X := PW - W;
    end else begin
      if AutoW then
        W := PW - X;
    end;

    if DecH then
      Y := Y - H
    else if DecHD2 then
      Y := Y - H / 2;
    if DecW then
      X := X - W;

  finally
    if StackList.Count > 0 then
      StackList.Delete(StackList.Count - 1);
  end;
end;

{ TTextSettingsBase }

function TTextSettingsBase.CalcTextHeight(const AText: string;
  SceneScale: Single): Single;
var
  S: TSizeF;
begin
  CalcTextObjectSize(AText, $FFFFFF, SceneScale, nil, S);
  Result := S.Height;
end;

function TTextSettingsBase.CalcTextObjectSize(const AText: string;
  const MaxWidth, SceneScale: Single; const Margins: TBounds; var Size: TSizeF): Boolean;
const
  FakeText = 'P|y'; // Do not localize

  function RoundToScale(const Value, Scale: Single): Single;
  begin
    if Scale > 0 then
      Result := Ceil(Value * Scale) / Scale
    else
      Result := Ceil(Value);
  end;

var
  LText: string;
  LMaxWidth: Single;
  Layout: TTextLayout;
begin
  Result := False;
  if (SceneScale >= 0) then
  begin
    if Margins <> nil then
      LMaxWidth := MaxWidth - Margins.Left - Margins.Right
    else
      LMaxWidth := MaxWidth;

    Layout := FLayout;
    if FPrefixStyle = TPrefixStyle.HidePrefix then
      LText := DelAmp(AText)
    else
      LText := AText;

    Layout.BeginUpdate;
    Layout.TopLeft := TPointF.Zero;
    if Layout.WordWrap and (LMaxWidth > 1) then
      Layout.MaxSize := TPointF.Create(LMaxWidth, TTextLayout.MaxLayoutSize.Y)
    else
      Layout.MaxSize := TTextLayout.MaxLayoutSize;
    if LText.IsEmpty then
      Layout.Text := FakeText
    else
      Layout.Text := LText;
    Layout.Trimming := FTrimming;
    Layout.VerticalAlign := TTextAlign.Leading;
    Layout.HorizontalAlign := TTextAlign.Leading;
    Layout.RightToLeft := False;
    Layout.EndUpdate;

    if LText.IsEmpty then begin
      Size.Width := 0;
    end else begin
      Size.Width := RoundToScale(FLayout.Width + FLayout.TextRect.Left * 2 + FLayout.Font.Size * 0.334, SceneScale);
    end;
    {$IFDEF ANDROID}
    //Size.Height := RoundToScale(FLayout.Height + FLayout.Font.Size * 0.334, SceneScale);
    Size.Height := RoundToScale(FLayout.Height, SceneScale);
//    if Size.Height > 50 then
//      Size.Height := Size.Height + FLayout.Font.Size * 0.6;
    {$ELSE}
    {$IFNDEF MSWINDOWS}
    //Size.Height := RoundToScale(FLayout.Height + FLayout.Font.Size * 0.2, SceneScale);
    Size.Height := RoundToScale(FLayout.Height, SceneScale);
    {$ELSE}
    Size.Height := RoundToScale(FLayout.Height, SceneScale);
    {$ENDIF}
    {$ENDIF}
//    {$IFNDEF MSWINDOWS}
// + FLayout.TextRect.Top * 2 + FLayout.Font.Size * 0.334
//    Size.Height := Size.Height + FLayout.Font.Size * 0.6;
//    {$ENDIF}

    if Margins <> nil then begin
      Size.Width := Size.Width + Margins.Left + Margins.Right;
      Size.Height := Size.Height + Margins.Top + Margins.Bottom;
    end;

    Result := True;
  end;
end;

function TTextSettingsBase.CalcTextWidth(const AText: string; SceneScale: Single): Single;
var
  S: TSizeF;
begin
  CalcTextObjectSize(AText, $FFFFFF, SceneScale, nil, S);
  Result := S.Width;
end;

procedure TTextSettingsBase.Change;
begin
  DoChange();
end;

constructor TTextSettingsBase.Create(AOwner: TComponent);
var
  DefaultValueService: IInterface;
  TrimmingDefault: TValue;
begin
  if AOwner is TControl then
    FOwner := TControl(AOwner)
  else FOwner := nil;

  FLayout := TTextLayoutManager.DefaultTextLayout.Create;
  FOnLastFontChanged := FLayout.Font.OnChanged;
  FLayout.Font.OnChanged := DoFontChanged;

  FPrefixStyle := TPrefixStyle.NoPrefix;
  if (csDesigning in AOwner.ComponentState) then begin
    FIsSizeChange := True;
    if TView(AOwner).SupportsPlatformService(IFMXDefaultPropertyValueService, DefaultValueService) then
    begin
      TrimmingDefault := IFMXDefaultPropertyValueService(DefaultValueService).GetDefaultPropertyValue(Self.ClassName, 'trimming');
      if not TrimmingDefault.IsEmpty then
        FTrimming := TrimmingDefault.AsType<TTextTrimming>;
    end;
  end else
    FIsSizeChange := False;
end;

destructor TTextSettingsBase.Destroy;
begin
  FreeAndNil(FLayout);
  inherited;
end;

procedure TTextSettingsBase.DoChange;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
  FIsSizeChange := False;
  FIsColorChange := False;
end;

procedure TTextSettingsBase.DoColorChanged(Sender: TObject);
begin
  FIsColorChange := True;
  DoChange;
end;

procedure TTextSettingsBase.DoFontChanged(Sender: TObject);
begin
  if Assigned(FOnLastFontChanged) then
    FOnLastFontChanged(Sender);
  FIsSizeChange := True;
  DoChange;
end;

procedure TTextSettingsBase.DoTextChanged;
begin
  if FAutoSize then FIsSizeChange := True;
  FIsEffectsChange := True;
  try
    DoChange;
  finally
    FIsEffectsChange := False;
  end;
end;

procedure TTextSettingsBase.Draw(const Canvas: TCanvas; const AText: string;
  const R: TRectF; const Opacity: Single; State: TViewState);
begin
  if AText <> '' then
    Draw(Canvas, AText, R, Opacity, State, FGravity);
end;

procedure TTextSettingsBase.Draw(const Canvas: TCanvas; const AText: string;
  const R: TRectF; const Opacity: Single; State: TViewState; AGravity: TLayoutGravity);
var
  V, H: TTextAlign;
begin
  if AText <> '' then begin
    V := TTextAlign.Leading;
    H := TTextAlign.Leading;
    case AGravity of
      TLayoutGravity.LeftBottom: V := TTextAlign.Trailing;
      TLayoutGravity.RightTop: H := TTextAlign.Trailing;
      TLayoutGravity.RightBottom:
        begin
          V := TTextAlign.Trailing;
          H := TTextAlign.Trailing;
        end;
      TLayoutGravity.CenterVertical: V := TTextAlign.Center;
      TLayoutGravity.CenterHorizontal: H := TTextAlign.Center;
      TLayoutGravity.CenterHBottom:
        begin
          H := TTextAlign.Center;
          V := TTextAlign.Trailing;
        end;
      TLayoutGravity.CenterVRight:
        begin
          H := TTextAlign.Trailing;
          V := TTextAlign.Center;
        end;
      TLayoutGravity.Center:
        begin
          H := TTextAlign.Center;
          V := TTextAlign.Center;
        end;
    end;
    FillText(Canvas, R, AText, Opacity, FillTextFlags, H, V, State);
  end;
end;

procedure TTextSettingsBase.Draw(const Canvas: TCanvas; const R: TRectF;
  const Opacity: Single; State: TViewState);
begin
  if FPrefixStyle = TPrefixStyle.HidePrefix then
    Draw(Canvas, DelAmp(FText), R, Opacity, State, FGravity)
  else
    Draw(Canvas, FText, R, Opacity, State, FGravity);
end;

procedure TTextSettingsBase.FillText(const Canvas: TCanvas; const ARect: TRectF;
  const AText: string; const AOpacity: Single;
  const Flags: TFillTextFlags; const ATextAlign, AVTextAlign: TTextAlign;
  State: TViewState);
begin
  with FLayout do begin
    BeginUpdate;
    TopLeft := ARect.TopLeft;
    MaxSize := PointF(ARect.Width, ARect.Height);
    Text := AText;
    WordWrap := Self.WordWrap;
    Opacity := AOpacity;
    HorizontalAlign := ATextAlign;
    VerticalAlign := AVTextAlign;
    Color := GetStateColor(State);
    Trimming := FTrimming;
    RightToLeft := TFillTextFlag.RightToLeft in Flags;
    EndUpdate;
    RenderLayout(Canvas);
  end;
end;

function TTextSettingsBase.GetFillTextFlags: TFillTextFlags;
begin
  if Assigned(FOwner) then
    Result := TView(FOwner).FillTextFlags
  else Result := [];
end;

function TTextSettingsBase.GetFont: TFont;
begin
  Result := FLayout.Font;
end;

function TTextSettingsBase.GetGravity: TLayoutGravity;
begin
  Result := FGravity;
end;

function TTextSettingsBase.GetHorzAlign: TTextAlign;
begin
  case FGravity of
    TLayoutGravity.None,
    TLayoutGravity.LeftTop, TLayoutGravity.LeftBottom, TLayoutGravity.CenterVertical:
      Result := TTextAlign.Leading;
    TLayoutGravity.CenterHorizontal, TLayoutGravity.CenterHBottom, TLayoutGravity.Center:
      Result := TTextAlign.Center;
  else
    Result := TTextAlign.Trailing;
  end;
end;

function TTextSettingsBase.GetTextLength: Integer;
begin
  Result := Length(FText);
end;

function TTextSettingsBase.GetVertAlign: TTextAlign;
begin
  case FGravity of
    TLayoutGravity.None,
    TLayoutGravity.LeftTop, TLayoutGravity.CenterHorizontal, TLayoutGravity.RightTop:
      Result := TTextAlign.Leading;
    TLayoutGravity.CenterVertical, TLayoutGravity.Center, TLayoutGravity.CenterVRight:
      Result := TTextAlign.Center;
  else
    Result := TTextAlign.Trailing;
  end;
end;

function TTextSettingsBase.GetWordWrap: Boolean;
begin
  Result := FLayout.WordWrap;
end;

function TTextSettingsBase.IsStoredGravity: Boolean;
begin
  Result := FGravity <> TLayoutGravity.None;
end;

procedure TTextSettingsBase.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize <> Value then begin
    FAutoSize := Value;
    if ([csLoading, csDesigning] * FOwner.ComponentState = [csDesigning]) and FAutoSize then
      FLayout.WordWrap := False;
    if FAutoSize then FIsSizeChange := True;
    DoChange;
  end;
end;

procedure TTextSettingsBase.SetFont(const Value: TFont);
begin
  if (FLayout.Font = nil) or (Value = nil) then Exit;
  FLayout.Font := Value;
end;

procedure TTextSettingsBase.SetGravity(const Value: TLayoutGravity);
begin
  if FGravity <> Value then begin
    FGravity := Value;
    DoChange;
  end;
end;

procedure TTextSettingsBase.SetHorzAlign(const Value: TTextAlign);
begin
  SetHorzVertValue(Value, VertAlign);
end;

procedure TTextSettingsBase.SetHorzVertValue(const H, V: TTextAlign);
begin
  case H of
    TTextAlign.Leading:
      begin
        case V of
          TTextAlign.Center: FGravity := TLayoutGravity.CenterHorizontal;
          TTextAlign.Leading: FGravity := TLayoutGravity.LeftTop;
          TTextAlign.Trailing: FGravity := TLayoutGravity.LeftBottom;
        end;
      end;
    TTextAlign.Center:
      begin
        case V of
          TTextAlign.Center: FGravity := TLayoutGravity.Center;
          TTextAlign.Leading: FGravity := TLayoutGravity.CenterVertical;
          TTextAlign.Trailing: FGravity := TLayoutGravity.CenterHBottom;
        end;
      end;
    TTextAlign.Trailing:
      begin
        case V of
          TTextAlign.Center: FGravity := TLayoutGravity.CenterVRight;
          TTextAlign.Leading: FGravity := TLayoutGravity.RightTop;
          TTextAlign.Trailing: FGravity := TLayoutGravity.RightBottom;
        end;
      end;
  end;
end;

procedure TTextSettingsBase.SetPrefixStyle(const Value: TPrefixStyle);
begin
  if FPrefixStyle <> Value then begin
    FPrefixStyle := Value;
    if FAutoSize then FIsSizeChange := True;
    DoChange;
  end;
end;

procedure TTextSettingsBase.SetText(const Value: string);
begin
  if FText <> Value then begin
    FText := Value;
    FIsTextChange := True;
    if FAutoSize then FIsSizeChange := True;
    DoTextChanged;
  end;
end;

procedure TTextSettingsBase.SetTrimming(const Value: TTextTrimming);
begin
  if FTrimming <> Value then begin
    FTrimming := Value;
    if FAutoSize then FIsSizeChange := True;
    DoChange;
  end;
end;

procedure TTextSettingsBase.SetVertAlign(const Value: TTextAlign);
begin
  SetHorzVertValue(HorzAlign, Value);
end;

procedure TTextSettingsBase.SetWordWrap(const Value: Boolean);
begin
  if FLayout.WordWrap <> Value then begin
    FLayout.WordWrap := Value;
    if FAutoSize then FIsSizeChange := True;
    DoChange;
  end;
end;

{ TTextSettings }

constructor TTextSettings.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := TTextColor.Create();
  FColor.OnChanged := DoColorChanged;
  FOpacity := 1;
end;

destructor TTextSettings.Destroy;
begin
  FreeAndNil(FColor);
  inherited Destroy;
end;

function TTextSettings.GetStateColor(const State: TViewState): TAlphaColor;
begin
  Result := FColor.GetStateColor(State);
  if FOpacity < 1 then
    TColorRec(Result).A := Round(TColorRec(Result).A * FOpacity);
end;

function TTextSettings.IsStoreOpacity: Boolean;
begin
  Result := FOpacity < 1;
end;

procedure TTextSettings.SetColor(const Value: TViewColor);
begin
  FColor.Assign(Value);
end;

procedure TTextSettings.SetOpacity(const Value: Single);
begin
  if FOpacity <> Value then begin
    FOpacity := Value;
    DoColorChanged(Self);
  end;
end;

{ TViewImageLink }

procedure TViewImageLink.Change;
begin
  if Assigned(OnChange) then
    OnChange(Images);
end;

constructor TViewImageLink.Create(AOwner: TDrawableIcon);
var
  LGlyph: IGlyph;

  procedure DoCreate();
  var
    FContext: TRttiContext;
    FType: TRttiType;
    FFiled: TRttiField;
    V: TValue;
  begin
    // ʹ�� RTTi ������������
    FContext := TRttiContext.Create;
    try
      FType := FContext.GetType(TGlyphImageLink);
      FFiled := FType.GetField('FOwner');
      if FFiled <> nil then begin
        V := AOwner.GetComponent;
        FFiled.SetValue(Self, V);
      end;
      FFiled := FType.GetField('FGlyph');
      if FFiled <> nil then begin
        V := V.From(LGlyph);
        FFiled.SetValue(Self, V);
      end;
    finally
      FContext.Free;
    end;
  end;

begin
  if AOwner = nil then
    raise EArgumentNilException.Create(SArgumentNil);
  if not AOwner.GetInterface(IGlyph, LGlyph) then
    raise EArgumentException.CreateFMT(SUnsupportedInterface, [AOwner.ClassName, 'IGlyph']);
  ImageIndex := -1;
  // DoCreate();
end;

{ TDrawableBorder }

procedure TDrawableBorder.Assign(Source: TPersistent);
begin
  if Source is TDrawableBorder then begin
    FBorder.Assign(TDrawableBorder(Source).FBorder);
  end;
  inherited Assign(Source);
end;

constructor TDrawableBorder.Create(View: IView; const ADefaultKind: TViewBrushKind;
  const ADefaultColor: TAlphaColor);
begin
  inherited Create(View, ADefaultKind, ADefaultColor);
end;

procedure TDrawableBorder.CreateBorder;
begin
  if FBorder = nil then begin
    FBorder := TViewBorder.Create;
    FBorder.OnChanged := DoChange;
  end;
end;

destructor TDrawableBorder.Destroy;
begin
  FreeAndNil(FBorder);
  inherited Destroy;
end;

procedure TDrawableBorder.DoDrawed(Canvas: TCanvas; var R: TRectF; AState: TViewState);
var
  TH: Single;
  LRect: TRectF;
begin
  if Assigned(FBorder) and (FBorder.FStyle <> TViewBorderStyle.None) and (FBorder.Width > 0) then begin
    if FBorder.Kind = TBrushKind.Solid then
      FBorder.Brush.Color :=  FBorder.Color.GetStateColor(AState);
    case FBorder.FStyle of
      TViewBorderStyle.RectBorder:
        begin
          if FBorder.Width > 0.1 then begin
            TH := FBorder.Width / 1.95;
            LRect.Left := R.Left + TH;
            LRect.Top := R.Top + TH;
            LRect.Right := R.Right - TH;
            LRect.Bottom := R.Bottom - TH;
            Canvas.DrawRect(LRect, XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
          end else
            Canvas.DrawRect(R, XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
      TViewBorderStyle.RectBitmap:
        begin
          Canvas.FillRect(R, XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
      TViewBorderStyle.LineEdit:
        begin
          Canvas.DrawLine(R.BottomRight, PointF(R.Left, R.Bottom), FView.Opacity, FBorder.Brush);
          TH := Min(6, Min(FBorder.Width * 4, R.Height / 4));
          Canvas.DrawLine(PointF(R.Left, R.Bottom - TH), PointF(R.Left, R.Bottom), FView.Opacity, FBorder.Brush);
          Canvas.DrawLine(PointF(R.Right, R.Bottom - TH), R.BottomRight, FView.Opacity, FBorder.Brush);
        end;
      TViewBorderStyle.LineTop:
        begin
          Canvas.FillRect(RectF(R.Left, R.Top, R.Right, R.Top + FBorder.Width),
            XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
      TViewBorderStyle.LineBottom:
        begin
          Canvas.FillRect(RectF(R.Left, R.Bottom - FBorder.Width, R.Right, R.Bottom),
            XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
      TViewBorderStyle.LineLeft:
        begin
          Canvas.FillRect(RectF(R.Left, R.Top, R.Left + FBorder.Width, R.Bottom),
            XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
      TViewBorderStyle.LineRight:
        begin
          Canvas.FillRect(RectF(R.Right - FBorder.Width, R.Top, R.Right, R.Bottom),
            XRadius, YRadius, FCorners, FView.Opacity, FBorder.Brush, FCornerType);
        end;
    end;
  end;
end;

procedure TDrawableBorder.DrawBorder(Canvas: TCanvas; var R: TRectF;
  AState: TViewState);
begin
  DoDrawed(Canvas, R, AState);
end;

function TDrawableBorder.GetBorder: TViewBorder;
begin
  if FBorder = nil then
    CreateBorder;
  Result := FBorder;
end;

function TDrawableBorder.GetEmpty: Boolean;
begin
  if Assigned(FBorder) and (FBorder.FStyle <> TViewBorderStyle.None) then
    Result := False
  else
    Result := inherited GetEmpty;
end;

procedure TDrawableBorder.SetBorder(const Value: TViewBorder);
begin
  FBorder.Assign(Value);
end;

{ TViewBorder }

procedure TViewBorder.Assign(Source: TPersistent);
var
  SaveChange: TNotifyEvent;
begin
  if Source is TViewBorder then begin
    SaveChange := FOnChanged;
    FOnChanged := nil;
    FColor.OnChanged := nil;
    FColor.Assign(TViewBorder(Source).FColor);
    FStyle := TViewBorder(Source).FStyle;
    FBrush.OnChanged := nil;
    FBrush.Assign(TViewBorder(Source).FBrush);
    FBrush.OnChanged := DoGradientChanged;
    FOnChanged := SaveChange;
    FColor.OnChanged := SaveChange;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end else
    inherited;
end;

constructor TViewBorder.Create(ADefaultStyle: TViewBorderStyle);
begin
  FBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Null);
  FBrush.OnChanged := DoGradientChanged;
  FColor := TViewColor.Create(TAlphaColorRec.Null);
  FStyle := ADefaultStyle;
  FDefaultStyle := ADefaultStyle;
end;

destructor TViewBorder.Destroy;
begin
  FColor.Free;
  FBrush.Free;
  inherited Destroy;
end;

procedure TViewBorder.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TViewBorder.DoGradientChanged(Sender: TObject);
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

function TViewBorder.GetBitmap: TBrushBitmap;
begin
  Result := FBrush.Bitmap;
end;

function TViewBorder.GetCap: TStrokeCap;
begin
  Result := FBrush.Cap;
end;

function TViewBorder.GetDash: TStrokeDash;
begin
  Result := FBrush.Dash;
end;

function TViewBorder.GetGradient: TGradient;
begin
  Result := FBrush.Gradient;
end;

function TViewBorder.GetJoin: TStrokeJoin;
begin
  Result := FBrush.Join;
end;

function TViewBorder.GetKind: TBrushKind;
begin
  Result := FBrush.Kind;
end;

function TViewBorder.GetWidth: Single;
begin
  Result := FBrush.Thickness;
end;

function TViewBorder.IsBitmapStored: Boolean;
begin
  Result := (FBrush.Kind = TBrushKind.Bitmap);
end;

function TViewBorder.IsGradientStored: Boolean;
begin
  Result := (FBrush.Kind = TBrushKind.Gradient);
end;

procedure TViewBorder.SetBitmap(const Value: TBrushBitmap);
begin
  if FBrush.Bitmap <> Value then begin
    FBrush.Bitmap := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetCap(const Value: TStrokeCap);
begin
  if FBrush.Cap <> Value then begin
    FBrush.Cap := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetColor(const Value: TViewColor);
begin
  FColor.Assign(Value);
end;

procedure TViewBorder.SetDash(const Value: TStrokeDash);
begin
  if FBrush.Dash <> Value then begin
    FBrush.Dash := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetGradient(const Value: TGradient);
begin
  if FBrush.Gradient <> Value then
    FBrush.Gradient := Value;
end;

procedure TViewBorder.SetJoin(const Value: TStrokeJoin);
begin
  if FBrush.Join <> Value then begin
    FBrush.Join := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetKind(const Value: TBrushKind);
begin
  if FBrush.Kind <> Value then begin
    FBrush.Kind := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetOnChanged(const Value: TNotifyEvent);
begin
  FOnChanged := Value;
  FColor.OnChanged := FOnChanged;
end;

procedure TViewBorder.SetStyle(const Value: TViewBorderStyle);
begin
  if FStyle <> Value then begin
    FStyle := Value;
    DoChanged;
  end;
end;

procedure TViewBorder.SetWidth(const Value: Single);
begin
  if Value <> FBrush.Thickness then begin
    FBrush.Thickness := Value;
    DoChanged;
  end;
end;

function TViewBorder.StyleStored: Boolean;
begin
  Result := FStyle <> FDefaultStyle;
end;

function TViewBorder.WidthStored: Boolean;
begin
  Result := Width <> 1;
end;

{ TViewBrushBase }

procedure TViewBrushBase.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TViewBrushBase then begin
    Self.FAccessoryType := TViewBrushBase(Source).FAccessoryType;
    Self.FAccessoryColor := TViewBrushBase(Source).FAccessoryColor;
    DoAccessoryChange;
  end;
end;

destructor TViewBrushBase.Destroy;
begin
  FreeAndNil(FAccessoryBmp);
  inherited;
end;

procedure TViewBrushBase.DoAccessoryChange;
begin
  if FAccessoryType <> TViewAccessoryType.None then begin
    if not Assigned(FAccessoryBmp) then
      FAccessoryBmp := TBitmap.Create;
    FAccessoryBmp.Assign(FAccessoryImages.GetAccessoryImage(FAccessoryType));
    if FAccessoryColor <> TAlphaColorRec.Null then
      ReplaceOpaqueColor(FAccessoryBmp, FAccessoryColor);
  end else
    FreeAndNil(FAccessoryBmp);
  if Assigned(OnChanged) then
    OnChanged(Self);
end;

function TViewBrushBase.GetKind: TViewBrushKind;
begin
  Result := TViewBrushKind(inherited Kind);
end;

function TViewBrushBase.IsKindStored: Boolean;
begin
  Result := inherited Kind <> DefaultKind;
end;

procedure TViewBrushBase.SetAccessoryColor(const Value: TAlphaColor);
begin
  if FAccessoryColor <> Value then begin
    FAccessoryColor := Value;
    DoAccessoryChange;
  end;
end;

procedure TViewBrushBase.SetAccessoryType(const Value: TViewAccessoryType);
begin
  if FAccessoryType <> Value then begin
    FAccessoryType := Value;
    DoAccessoryChange;
  end;
end;

procedure TViewBrushBase.SetKind(const Value: TViewBrushKind);
begin
  inherited Kind := TBrushKind(Value);
end;

{ TViewBrush }

constructor TViewBrush.Create(const ADefaultKind: TViewBrushKind;
  const ADefaultColor: TAlphaColor);
var
  Bmp: TBrushBitmap;
begin
  inherited Create(TBrushKind(ADefaultKind), ADefaultColor);
  Bmp := inherited Bitmap;
  Bmp.Free;
  inherited Bitmap := nil;
  Bmp := TPatch9Bitmap.Create;
  Bmp.OnChanged := Self.BitmapChanged;
  Bmp.Bitmap.OnChange := Self.BitmapChanged;
  TPatch9Bitmap(Bmp).FBounds.OnChange := Self.BitmapChanged;
  inherited Bitmap := Bmp;
end;

function TViewBrush.GetBitmap: TPatch9Bitmap;
begin
  Result := TPatch9Bitmap(inherited Bitmap);
end;

function TViewBrush.IsPatch9BitmapStored: Boolean;
begin
  Result := Kind in [TViewBrushKind.Bitmap, TViewBrushKind.Patch9Bitmap];
end;

procedure TViewBrush.SetBitmap(const Value: TPatch9Bitmap);
begin
  inherited Bitmap.Assign(Value);
end;

{ TPatch9Bitmap }

procedure TPatch9Bitmap.Assign(Source: TPersistent);
begin
  if Source is TPatch9Bitmap then
    FBounds.Assign(TPatch9Bitmap(Source).FBounds);
  inherited;
end;

constructor TPatch9Bitmap.Create;
begin
  inherited Create;
  FBounds := TPatchBounds.Create(RectF(0, 0, 0, 0));
  FBounds.OnChange := Bitmap.OnChange;
end;

destructor TPatch9Bitmap.Destroy;
begin
  FBounds.Free;
  inherited;
end;

procedure TPatch9Bitmap.SetBounds(const Value: TPatchBounds);
begin
  FBounds.Assign(Value);
end;

procedure TPatch9Bitmap.SetRemoveBlackLine(const Value: Boolean);
begin
  if FRemoveBlackLine <> Value then begin
    FRemoveBlackLine := Value;
    if Assigned(OnChanged) then
      OnChanged(Self);
  end;
end;

{ TViewAccessoryImageList }

procedure TViewAccessoryImageList.AddBackAccessory;
var
  AAcc: TBitmap;
begin
  AAcc := TBitmap.Create;
  AAcc.SetSize(64, 64);
  AAcc.Clear(claNull);
  AAcc.Canvas.BeginScene;
  try
    AAcc.Canvas.Fill.Color := claSilver;
    AAcc.Canvas.FillPolygon([
      PointF(40, 0),
      PointF(46, 6),
      PointF(21, 31.5),
      PointF(46, 56),
      PointF(40, 63),
      PointF(9, 31.5),
      PointF(40, 0)
    ], 1);
  finally
    AAcc.Canvas.EndScene;
  end;
  Add(AAcc);
end;

procedure TViewAccessoryImageList.AddEllipsesAccessory;
var
  AAcc: TBitmap;
  ARect: TRectF;
  ASpacing: single;
  ASize: single;
begin
  AAcc := TBitmap.Create;
  AAcc.SetSize(Round(32 * GetScreenScale), Round(32 * GetScreenScale));
  ASize := 7 * GetScreenScale;
  ASpacing := (AAcc.Width - (3 * ASize)) / 2;

  AAcc.Clear(claNull);
  AAcc.Canvas.BeginScene;
  try
    AAcc.Canvas.Fill.Color := claSilver;
    ARect := RectF(0, 0, ASize, ASize);
    OffsetRect(ARect, 0, (AAcc.Height - ARect.Height) / 2);
    AAcc.Canvas.FillEllipse(ARect, 1);
    OffsetRect(ARect, ASize+ASpacing, 0);
    AAcc.Canvas.FillEllipse(ARect, 1);
    OffsetRect(ARect, ASize+ASpacing, 0);
    AAcc.Canvas.FillEllipse(ARect, 1);
  finally
    AAcc.Canvas.EndScene;
  end;
  Add(AAcc);
end;

procedure TViewAccessoryImageList.AddFlagAccessory;
var
  AAcc: TBitmap;
  ARect: TRectF;
  s: single;
  r1, r2: TRectF;
begin
  s := GetScreenScale;
  AAcc := TBitmap.Create;
  AAcc.SetSize(Round(32 * s), Round(32 * s));
  AAcc.Clear(claNull);
  ARect := RectF(0, 0, AAcc.Width, AAcc.Height);
  ARect.Inflate(0-(AAcc.Width / 4), 0-(AAcc.Height / 7));


  AAcc.Canvas.BeginScene;
  try
    r1 := ARect;
    r2 := ARect;

    r2.Top := ARect.Top + (ARect.Height / 12);


    r2.Left := r2.Left;
    r2.Height := ARect.Height / 2;
    AAcc.Canvas.stroke.Color := claSilver;
    AAcc.Canvas.Stroke.Thickness := s*2;
    AAcc.Canvas.Fill.Color := claSilver;
    AAcc.Canvas.FillRect(r2, 0, 0, AllCorners, 1);
    AAcc.Canvas.DrawLine(r1.TopLeft, PointF(r1.Left, r1.Bottom), 1);
  finally
    AAcc.Canvas.EndScene;
  end;
  Add(AAcc);
end;

procedure TViewAccessoryImageList.CalculateImageScale;
begin
  if FImageScale = 0 then
  begin
    FImageScale := Min(Trunc(GetScreenScale), 3);
    {$IFDEF MSWINDOWS}
    FImageScale := 1;
    {$ENDIF}
  end;
end;

constructor TViewAccessoryImageList.Create;
begin
  inherited Create(True);
  FImageScale := 0;
  FImageMap := TBitmap.Create;
end;

destructor TViewAccessoryImageList.Destroy;
begin
  FreeAndNil(FImageMap);
  if FActiveStyle <> nil then
    FreeAndNil(FActiveStyle);
  inherited;
end;

procedure TViewAccessoryImageList.Draw(ACanvas: TCanvas; const ARect: TRectF;
  AAccessory: TViewAccessoryType; const AOpacity: Single; const AStretch: Boolean);
var
  R: TRectF;
  Bmp: TBitmap;
begin
  Bmp := GetAccessoryImage(AAccessory);
  if not Assigned(Bmp) then
    Exit;
  if AStretch = False then begin
    R := RectF(0, 0, Bmp.Width / GetScreenScale, Bmp.Height / GetScreenScale);
    OffsetRect(R, ARect.Left, ARect.Top);
    OffsetRect(R, (ARect.Width - R.Width) * 0.5, (ARect.Height - R.Height) * 0.5);
    ACanvas.DrawBitmap(Bmp, RectF(0, 0, Bmp.Width, Bmp.Height), R, AOpacity, True);
  end else
    ACanvas.DrawBitmap(Bmp, RectF(0, 0, Bmp.Width, Bmp.Height), ARect, AOpacity, True);
end;

function TViewAccessoryImageList.GetAccessoryFromResource(const AStyleName: string;
  const AState: string): TBitmap;
var
  AStyleObj: TStyleObject;
  AImgRect: TBounds;
  AIds: TStrings;
  ABitmapLink: TBitmapLinks;
  AImageMap: TBitmap;
begin
  CalculateImageScale;

  Result := TBitmap.Create;
  AIds := TStringList.Create;
  try
    AIds.Text := StringReplace(AStyleName, '.', #13, [rfReplaceAll]);
    AStyleObj := TStyleObject(TStyleManager.ActiveStyle(nil));

    while AIds.Count > 0 do begin
      AStyleObj := TStyleObject(AStyleObj.FindStyleResource(AIds[0]));
      AIds.Delete(0);
    end;

    if AStyleObj <> nil then begin
      if FImageMap.IsEmpty then begin
        AImageMap := ((AStyleObj as TStyleObject).Source.MultiResBitmap.Bitmaps[FImageScale]);

        FImageMap.SetSize(Round(AImageMap.Width), Round(AImageMap.Height));
        FImageMap.Clear(claNull);

        FImageMap.Canvas.BeginScene;
        try
          FImageMap.Canvas.DrawBitmap(AImageMap,
              RectF(0, 0, AImageMap.Width, AImageMap.Height),
              RectF(0, 0, FImageMap.Width, FImageMap.Height),
              1,
              True);
        finally
          FImageMap.Canvas.EndScene;
        end;
      end;

      ABitmapLink := nil;
      if AStyleObj = nil then
        Exit;
      if (AStyleObj.ClassType = TCheckStyleObject) then begin
        if AState = 'checked' then
          ABitmapLink := TCheckStyleObject(AStyleObj).ActiveLink
        else
          ABitmapLink := TCheckStyleObject(AStyleObj).SourceLink
      end;

      if ABitmapLink = nil then
        ABitmapLink := AStyleObj.SourceLink;

      {$IFDEF XE8_OR_NEWER}
      AImgRect := ABitmapLink.LinkByScale(FImageScale, True).SourceRect;
      {$ELSE}
      AImgRect := ABitmapLink.LinkByScale(FImageScale).SourceRect;
      {$ENDIF}
      Result.SetSize(Round(AImgRect.Width), Round(AImgRect.Height));
      Result.Clear(claNull);
      Result.Canvas.BeginScene;

      Result.Canvas.DrawBitmap(FImageMap, AImgRect.Rect, RectF(0, 0, Result.Width,
        Result.Height), 1, True);
      Result.Canvas.EndScene;
    end;
  finally
    {$IFDEF NEXTGEN}
    FreeAndNil(AIds);
    {$ELSE}
    AIds.Free;
    {$ENDIF}
  end;
end;

function TViewAccessoryImageList.GetAccessoryImage(
  AAccessory: TViewAccessoryType): TBitmap;
begin
  if Count = 0 then
    Initialize;
  Result := Items[Ord(AAccessory)];
end;

procedure TViewAccessoryImageList.SetAccessoryImage(
  AAccessory: TViewAccessoryType; const Value: TBitmap);
begin
  if Count = 0 then
    Initialize;
  Items[Ord(AAccessory)].Assign(Value);
end;

procedure TViewAccessoryImageList.Initialize;
var
  ICount: TViewAccessoryType;
begin
  for ICount := Low(TViewAccessoryType) to High(TViewAccessoryType) do
  begin
    case ICount of
      TViewAccessoryType.None: Add(GetAccessoryFromResource('none'));
      TViewAccessoryType.More: Add(GetAccessoryFromResource('listviewstyle.accessorymore'));
      TViewAccessoryType.Checkmark: Add(GetAccessoryFromResource('listviewstyle.accessorycheckmark'));
      TViewAccessoryType.Detail: Add(GetAccessoryFromResource('listviewstyle.accessorydetail'));
      TViewAccessoryType.Ellipses: AddEllipsesAccessory;
      TViewAccessoryType.Flag: AddFlagAccessory;
      TViewAccessoryType.Back: AddBackAccessory;// Add(GetAccessoryFromResource('backtoolbutton.icon'));
      TViewAccessoryType.Refresh: Add(GetAccessoryFromResource('refreshtoolbutton.icon'));
      TViewAccessoryType.Action: Add(GetAccessoryFromResource('actiontoolbutton.icon'));
      TViewAccessoryType.Play: Add(GetAccessoryFromResource('playtoolbutton.icon'));
      TViewAccessoryType.Rewind: Add(GetAccessoryFromResource('rewindtoolbutton.icon'));
      TViewAccessoryType.Forwards: Add(GetAccessoryFromResource('forwardtoolbutton.icon'));
      TViewAccessoryType.Pause: Add(GetAccessoryFromResource('pausetoolbutton.icon'));
      TViewAccessoryType.Stop: Add(GetAccessoryFromResource('stoptoolbutton.icon'));
      TViewAccessoryType.Add: Add(GetAccessoryFromResource('addtoolbutton.icon'));
      TViewAccessoryType.Prior: Add(GetAccessoryFromResource('priortoolbutton.icon'));
      TViewAccessoryType.Next: Add(GetAccessoryFromResource('nexttoolbutton.icon'));
      TViewAccessoryType.ArrowUp: Add(GetAccessoryFromResource('arrowuptoolbutton.icon'));
      TViewAccessoryType.ArrowDown: Add(GetAccessoryFromResource('arrowdowntoolbutton.icon'));
      TViewAccessoryType.ArrowLeft: Add(GetAccessoryFromResource('arrowlefttoolbutton.icon'));
      TViewAccessoryType.ArrowRight: Add(GetAccessoryFromResource('arrowrighttoolbutton.icon'));
      TViewAccessoryType.Reply: Add(GetAccessoryFromResource('replytoolbutton.icon'));
      TViewAccessoryType.Search: Add(GetAccessoryFromResource('searchtoolbutton.icon'));
      TViewAccessoryType.Bookmarks: Add(GetAccessoryFromResource('bookmarkstoolbutton.icon'));
      TViewAccessoryType.Trash: Add(GetAccessoryFromResource('trashtoolbutton.icon'));
      TViewAccessoryType.Organize: Add(GetAccessoryFromResource('organizetoolbutton.icon'));
      TViewAccessoryType.Camera: Add(GetAccessoryFromResource('cameratoolbutton.icon'));
      TViewAccessoryType.Compose: Add(GetAccessoryFromResource('composetoolbutton.icon'));
      TViewAccessoryType.Info: Add(GetAccessoryFromResource('infotoolbutton.icon'));
      TViewAccessoryType.Pagecurl: Add(GetAccessoryFromResource('pagecurltoolbutton.icon'));
      TViewAccessoryType.Details: Add(GetAccessoryFromResource('detailstoolbutton.icon'));
      TViewAccessoryType.RadioButton: Add(GetAccessoryFromResource('radiobuttonstyle.background'));
      TViewAccessoryType.RadioButtonChecked: Add(GetAccessoryFromResource('radiobuttonstyle.background', 'checked'));
      TViewAccessoryType.CheckBox: Add(GetAccessoryFromResource('checkboxstyle.background'));
      TViewAccessoryType.CheckBoxChecked: Add(GetAccessoryFromResource('checkboxstyle.background', 'checked'));
      TViewAccessoryType.UserDefined1: Add(GetAccessoryFromResource('userdefined1'));
      TViewAccessoryType.UserDefined2: Add(GetAccessoryFromResource('userdefined2'));
      TViewAccessoryType.UserDefined3: Add(GetAccessoryFromResource('userdefined3'));
    end;
  end;
end;

{ TViewImagesBrush }

constructor TViewImagesBrush.Create(const ADefaultKind: TBrushKind;
  const ADefaultColor: TAlphaColor);
begin
  inherited Create(ADefaultKind, ADefaultColor);
  FImageIndex := -1;
end;

function TViewImagesBrush.GetComponent: TComponent;
var
  LI: IInterfaceComponentReference;
begin
  if Assigned(FOwner) and (Supports(FOwner, IInterfaceComponentReference, LI)) then
    Result := LI.GetComponent
  else
    Result := nil;
end;

function TViewImagesBrush.GetImageIndex: TImageIndex;
begin
  Result := FImageIndex;
end;

function TViewImagesBrush.GetImageList: TBaseImageList;
var
  LI: IGlyph;
begin
  if Assigned(FOwner) and (Supports(FOwner, IGlyph, LI)) then
    Result := LI.Images
  else
    Result := nil;
end;

procedure TViewImagesBrush.ImagesChanged;
begin
  if Assigned(OnChanged) then
    OnChanged(Self);
end;

function TViewImagesBrush.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := S_OK
  else Result := E_NOINTERFACE
end;

procedure TViewImagesBrush.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex <> Value then begin
    FImageIndex := Value;
    if Assigned(OnChanged) then
      OnChanged(Self);
  end;
end;

procedure TViewImagesBrush.SetImageList(const Value: TBaseImageList);
var
  LI: IGlyph;
begin
  if Assigned(FOwner) and (Supports(FOwner, IGlyph, LI)) then
    LI.Images := Value;
end;

procedure TViewImagesBrush.SetImages(const Value: TCustomImageList);
var
  LI: IGlyph;
begin
  if Assigned(FOwner) and (Supports(FOwner, IGlyph, LI)) then
    LI.Images := Value;
end;

function TViewImagesBrush._AddRef: Integer;
begin
  Result := -1;
end;

function TViewImagesBrush._Release: Integer;
begin
  Result := -1;
end;

{ TScrollCalculations }

constructor TScrollCalculations.Create(AOwner: TPersistent);
begin
  if not (AOwner is TView) then
    raise EArgumentException.Create('Argument Invalid.');
  inherited Create(AOwner);
  FScrollView := TView(AOwner);
end;

procedure TScrollCalculations.DoChanged;
begin
  if (FScrollView <> nil) and not (csDestroying in FScrollView.ComponentState) then
    FScrollView.InternalAlign;
  inherited;
end;

procedure TScrollCalculations.DoStart;
begin
  inherited;
  if (FScrollView <> nil) and not (csDestroying in FScrollView.ComponentState) then
    FScrollView.StartScrolling;
end;

procedure TScrollCalculations.DoStop;
begin
  inherited;
  if (FScrollView <> nil) and not (csDestroying in FScrollView.ComponentState) then
    FScrollView.StopScrolling;
end;

{ TScrollBarHelper }

function TScrollBarHelper.GetMaxD: Double;
begin
  Result := ValueRange.Max;
end;

function TScrollBarHelper.GetMinD: Double;
begin
  Result := ValueRange.Min;
end;

function TScrollBarHelper.GetValueD: Double;
begin
  Result := ValueRange.Value;
end;

function TScrollBarHelper.GetViewportSizeD: Double;
begin
  Result := ValueRange.ViewportSize;
end;

procedure TScrollBarHelper.SetMaxD(const Value: Double);
begin
  ValueRange.Max := Value;
end;

procedure TScrollBarHelper.SetMinD(const Value: Double);
begin
  ValueRange.Min := Value;
end;

procedure TScrollBarHelper.SetValueD(const Value: Double);
begin
  ValueRange.Value := Value;
end;

procedure TScrollBarHelper.SetViewportSizeD(const Value: Double);
begin
  ValueRange.ViewportSize := Value;
end;

{ TCustomTrackHelper }

function TCustomTrackHelper.GetMaxD: Double;
begin
  Result := ValueRange.Max;
end;

function TCustomTrackHelper.GetMinD: Double;
begin
  Result := ValueRange.Min;
end;

function TCustomTrackHelper.GetValueD: Double;
begin
  Result := ValueRange.Value;
end;

function TCustomTrackHelper.GetViewportSizeD: Double;
begin
  Result := ValueRange.ViewportSize;
end;

procedure TCustomTrackHelper.SetMaxD(const Value: Double);
begin
  ValueRange.Max := Value;
end;

procedure TCustomTrackHelper.SetMinD(const Value: Double);
begin
  ValueRange.Min := Value;
end;

procedure TCustomTrackHelper.SetValueD(const Value: Double);
begin
  ValueRange.Value := Value;
end;

procedure TCustomTrackHelper.SetViewportSizeD(const Value: Double);
begin
  ValueRange.ViewportSize := Value;
end;

{ TGridsLayout }

constructor TGridsLayout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNumColumns := 0;
  FColumnWidth := CDefaultColumnWidth;
  FColumnHeight := CDefaultColumnHeight;
  FStretchMode := TViewStretchMode.None;
  FSpacingBorder := True;
  FVerticalSpacing := 0;
  FHorizontalSpacing := 0;
  FLastRows := 0;
  FLastColumns := 0;
  FDividerBrush := TBrush.Create(TBrushKind.Solid, TAlphaColorRec.Null);
  FDividerBrush.Color := CDefaultDividerColor;
  FForceColumnSize := False;
end;

destructor TGridsLayout.Destroy;
begin
  FreeAndNil(FDividerBrush);
  inherited Destroy;
end;

procedure TGridsLayout.DoRealign;
var
  I, CtrlCount: Integer;
  LColumns: Integer;
  LItemWidth, LItemHeight, AW: Single;
  CurPos: TPointD;
  VL, VT, VW, VH, PW: Double;
  Control: TControl;
  View: IView;
  SaveAdjustViewBounds, LAutoSize: Boolean;
  LStretchMode: TViewStretchMode;
begin
  if FDisableAlign then
    Exit;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  //LogD(Self.ClassName + '.DoRealign.');

  FDisableAlign := True;

  // �õ�������Ŀ�ʼ����
  if FSpacingBorder then begin
    CurPos := TPointD.Create(Padding.Left + FHorizontalSpacing, Padding.Top + FVerticalSpacing);
    VW := Width - CurPos.X - Padding.Right - FHorizontalSpacing;
    VH := Height - CurPos.Y - Padding.Bottom - FVerticalSpacing;
  end else begin
    CurPos := TPointD.Create(Padding.Left, Padding.Top);
    VW := Width - CurPos.X - Padding.Right;
    VH := Height - CurPos.Y - Padding.Bottom;
  end;
  CtrlCount := ControlsCount;
  LColumns := AbsoluteColumnsNum;
  if FColumnWidth < 0 then
    LItemWidth := CDefaultColumnWidth
  else
    LItemWidth := FColumnWidth;

  if (FNumColumns > 0) and (FWidthSize = TViewSize.WrapContent) then begin
    VW := LColumns * (LItemWidth + FHorizontalSpacing) - FHorizontalSpacing;
    if FStretchMode = FStretchMode then
      VW := VW + FHorizontalSpacing * 2;
  end;

  PW := 0;
  VL := 0;

  // ������� > 0 ���ӿؼ� > 0 ʱ�Ŵ�����
  if ((VW > 0) and (VH > 0)) or (CtrlCount > 0) then begin
    AW := VW + CurPos.X;

    // ��������ģʽ�������ÿ�еĿ�ȡ��հ״�С��ʵ��ʹ�õ�����ģʽ
    LStretchMode := FStretchMode;
    case FStretchMode of
      TViewStretchMode.None:
        begin
          LStretchMode := TViewStretchMode.None;
        end;
      TViewStretchMode.SpacingWidth:
        begin
          if LColumns > 1 then begin
            LStretchMode := TViewStretchMode.SpacingWidth;
            if csDesigning in ComponentState then begin
              I := GetCount;
              if LColumns > I then
                LColumns := I;
            end else begin
              if LColumns > CtrlCount then
                LColumns := CtrlCount;
            end;
            PW := (VW - LItemWidth) / (LColumns - 1) - LItemWidth;
            if PW < 0 then PW := 0;
            if FSpacingBorder then
              AW := AW - FHorizontalSpacing;
          end else begin
            LStretchMode := TViewStretchMode.None;
          end;
        end;
      TViewStretchMode.ColumnWidth:
        begin
          if LColumns > 0 then begin
            if csDesigning in ComponentState then begin
              I := GetCount;
              if LColumns > I then
                LColumns := I;
            end else begin
              if LColumns > CtrlCount then
                LColumns := CtrlCount;
            end;
            LStretchMode := TViewStretchMode.ColumnWidth;
            LItemWidth := (VW + FHorizontalSpacing) / LColumns - FHorizontalSpacing;
            if FSpacingBorder then
              AW := AW - FHorizontalSpacing;
          end else begin
            LStretchMode := TViewStretchMode.None;
          end;
        end;
      TViewStretchMode.SpacingWidthUniform:
        begin
          if LColumns > 0 then begin
            if csDesigning in ComponentState then begin
              I := GetCount;
              if LColumns > I then
                LColumns := I;
            end else begin
              if LColumns > CtrlCount then
                LColumns := CtrlCount;
            end;
            LStretchMode := TViewStretchMode.SpacingWidthUniform;
            if FSpacingBorder then
              PW := (VW - LItemWidth * LColumns + FHorizontalSpacing * 2) / (LColumns + 1)
            else
              PW := (VW - LItemWidth * LColumns) / (LColumns + 1);
            if PW < 0 then PW := 0;
            CurPos.X := Padding.Left;
            AW := AW - PW;
            if not FSpacingBorder then
              AW := AW - FHorizontalSpacing;
          end else begin
            LStretchMode := TViewStretchMode.None;
          end;
        end;
    end;

    if LStretchMode = TViewStretchMode.None then begin
      AW := AW - LItemWidth;
      //if FSpacingBorder then
      //  AW := AW - FHorizontalSpacing;
    end;

    if FColumnHeight < 0 then
      LItemHeight := CDefaultColumnHeight
    else
      LItemHeight := FColumnHeight;

    FLastColumns := LColumns;
    FLastRows := 1;
    FLastRH := LItemHeight;
    FLastCW := LItemWidth;
    FLastPW := PW;
    FLastStretchMode := LStretchMode;
    VW := 0;

    for I := 0 to CtrlCount - 1 do begin
      Control := Controls[I];
      if not Control.Visible then Continue;
      {$IFDEF MSWINDOWS}
      // ��������״̬������� DesignerControl ʱ����
      if IsDesignerControl(Control) then
        Continue;
      {$ENDIF}

      if CurPos.X > AW then begin
        if (LStretchMode = TViewStretchMode.SpacingWidthUniform) or (not FSpacingBorder) then
          CurPos.X := Padding.Left
        else
          CurPos.X := Padding.Left + FHorizontalSpacing;
        CurPos.Y := CurPos.Y + LItemHeight + FVerticalSpacing;
        if FLastRows = 1 then begin
          if I > FLastColumns then
            FLastColumns := I;
        end;
        Inc(FLastRows);
      end;

      // �õ����IView�ӿڣ����Ƿ����������С��С����
      View := nil;
      if (Supports(Control, IView, View)) then
        SaveAdjustViewBounds := View.GetAdjustViewBounds
      else
        SaveAdjustViewBounds := False;

      case LStretchMode of
        TViewStretchMode.None: // ���Զ�������С
          begin
            if FForceColumnSize then
              LAutoSize := True
            else begin
              if Assigned(View) then
                LAutoSize := View.GetWidthSize = TViewSize.FillParent
              else begin
                LAutoSize := Control.Align in [TAlignLayout.Top, TAlignLayout.Bottom,
                  TAlignLayout.MostTop, TAlignLayout.MostBottom,
                  TAlignLayout.Client, TAlignLayout.Contents,
                  TAlignLayout.VertCenter, TAlignLayout.Horizontal, TAlignLayout.Fit,
                  TAlignLayout.FitLeft, TAlignLayout.FitRight];
              end;
            end;
            if LAutoSize then begin
              // �Զ����
              VL := CurPos.X + Control.Margins.Left;
              VW := LItemWidth - Control.Margins.Left - Control.Margins.Right;
            end else begin
              VW := Control.Width;
              // ���Զ����
              case FGravity of
                TLayoutGravity.LeftTop, TLayoutGravity.LeftBottom:
                  VL := CurPos.X + Control.Margins.Left;
                TLayoutGravity.RightTop, TLayoutGravity.RightBottom, TLayoutGravity.CenterVRight:
                  VL := CurPos.X + (LItemWidth - VW - Control.Margins.Right);
                TLayoutGravity.CenterHorizontal, TLayoutGravity.CenterHBottom, TLayoutGravity.Center:
                  VL := CurPos.X + (LItemWidth - (VW + Control.Margins.Left + Control.Margins.Right)) * 0.5 + Control.Margins.Left;
              else
                begin
                  case Control.Align of
                    TAlignLayout.Left, TAlignLayout.MostLeft:
                      VL := CurPos.X + Control.Margins.Left;
                    TAlignLayout.Center, TAlignLayout.HorzCenter:
                      VL := CurPos.X + (LItemWidth - (VW + Control.Margins.Left + Control.Margins.Right)) * 0.5 + Control.Margins.Left;
                    TAlignLayout.Right, TAlignLayout.MostRight:
                      VL := CurPos.X + (LItemWidth - VW - Control.Margins.Right);
                  else
                    VL := CurPos.X;
                  end;
                end;
              end;
            end;
            CurPos.X := CurPos.X + LItemWidth + FHorizontalSpacing;
          end;

        TViewStretchMode.SpacingWidth: // �Զ������������
          begin
            VL := CurPos.X + Control.Margins.Left;
            VW := LItemWidth - Control.Margins.Left - Control.Margins.Right;
            CurPos.X := CurPos.X + LItemWidth + PW;
          end;

        TViewStretchMode.ColumnWidth:
          begin
            VL := CurPos.X + Control.Margins.Left;
            VW := LItemWidth - Control.Margins.Left - Control.Margins.Right;
            CurPos.X := CurPos.X + LItemWidth + FHorizontalSpacing;
          end;

        TViewStretchMode.SpacingWidthUniform:
          begin
            VL := CurPos.X + Control.Margins.Left + PW;
            VW := LItemWidth - Control.Margins.Left - Control.Margins.Right;
            CurPos.X := CurPos.X + LItemWidth + PW;
          end;
      else
        Continue;
      end;

      // �ж�����ڴ�ֱ�����Ƿ��Զ���С
      if FForceColumnSize then
        LAutoSize := True
      else begin
        if Assigned(View) then
          LAutoSize := View.GetHeightSize = TViewSize.FillParent
        else begin
          LAutoSize := Control.Align in [TAlignLayout.Left, TAlignLayout.Right,
            TAlignLayout.MostLeft, TAlignLayout.MostRight,
            TAlignLayout.Client, TAlignLayout.Contents,
            TAlignLayout.HorzCenter, TAlignLayout.Vertical, TAlignLayout.Fit,
            TAlignLayout.FitLeft, TAlignLayout.FitRight]
        end;
      end;

      // ����ȴ�С����
      if SaveAdjustViewBounds then begin
        if (View.GetMaxWidth > 0) and (VW > View.GetMaxWidth) then
          VW := View.GetMaxWidth;
        if (View.GetMinWidth > 0) and (VW < View.GetMinWidth) then
          VW := View.GetMinWidth;
      end;

      if LAutoSize then begin
        // �Զ��߶�ʱ
        VT := CurPos.Y + Control.Margins.Top;
        VH := LItemHeight - Control.Margins.Bottom - Control.Margins.Top;
        // ���߶ȴ�С����
        if SaveAdjustViewBounds then begin
          if (View.GetMaxHeight > 0) and (VH > View.GetMaxHeight) then
            VH := View.GetMaxHeight;
          if (View.GetMinHeight > 0) and (VH < View.GetMinHeight) then
            VH := View.GetMinHeight;
        end;
      end else begin
        // ���Զ��߶�ʱ������������������λ��
        VH := Control.Height;
        case FGravity of
          TLayoutGravity.LeftTop, TLayoutGravity.RightTop:
            // ����
            VT := CurPos.Y + Control.Margins.Top;
          TLayoutGravity.LeftBottom, TLayoutGravity.RightBottom, TLayoutGravity.CenterHBottom:
            // �ײ�
            VT := CurPos.Y + (LItemHeight - VH - Control.Margins.Bottom);
          TLayoutGravity.CenterVertical, TLayoutGravity.Center, TLayoutGravity.CenterVRight:
            // ����
            VT := CurPos.Y + (LItemHeight - (VH + Control.Margins.Top + Control.Margins.Bottom)) * 0.5 + Control.Margins.Top;
        else 
          begin
            case Control.Align of
              TAlignLayout.Top, TAlignLayout.MostTop:
                VT := CurPos.Y + Control.Margins.Top;
              TAlignLayout.Center, TAlignLayout.VertCenter:
                VT := CurPos.Y + (LItemHeight - (VH + Control.Margins.Top + Control.Margins.Bottom)) * 0.5 + Control.Margins.Top;
              TAlignLayout.Bottom, TAlignLayout.MostBottom:
                VT := CurPos.Y + (LItemHeight - VH - Control.Margins.Bottom);
            else
              VT := CurPos.Y;
            end;
          end;
        end;
      end;

      // ���������С
      if Assigned(View) then begin
        Control.SetBounds(VL, VT, VW, VH);
      end else
        Control.SetBounds(VL, VT, VW, VH);

    end;

    if FLastRows = 1 then
      FLastColumns := CtrlCount;

    // �ж��Ƿ������СΪ�����ݡ�����ǣ��������ݴ�С������С
    if (WidthSize = TViewSize.WrapContent) then begin
      if LColumns > CtrlCount then
        LColumns := CtrlCount;
      VW := LColumns * (LItemWidth + FHorizontalSpacing) + FHorizontalSpacing + Padding.Left + Padding.Right; 
      PW := GetParentMaxWidth;
      if (VW > PW) and (PW > 0) then
        VW := PW;
    end else
      VW := Width;
    
    if (HeightSize = TViewSize.WrapContent) then begin
      VH := CurPos.Y + LItemHeight + Padding.Bottom;
      if FSpacingBorder then
        VH := VH + FVerticalSpacing;
      PW := GetParentMaxHeight;
      if (VH > PW) and (PW > 0) then
        VH := PW;
    end else 
      VH := Height;

    if (WidthSize = TViewSize.WrapContent) or (HeightSize = TViewSize.WrapContent) then begin
      if (Height <> VH) or (Width <> VW) then      
        SetBounds(Position.X, Position.Y, VW, VH);
    end;

  end else begin
    FLastColumns := 0;
    FLastRows := 0;
  end;

  FDisableAlign := False;
end;

procedure TGridsLayout.DrawDivider(Canvas: TCanvas);
var
  I, J, S: Integer;
  X, Y, W, H: Single;
begin
  if FSpacingBorder then
    S := 0
  else
    S := 1;
  // ��ֱ����
  if FVerticalSpacing > 0 then begin
    J := FLastRows;
    if FSpacingBorder then begin
      Y := Padding.Top;
      X := Padding.Left;
      W := Width - Padding.Right;
    end else begin
      Y := Padding.Top + FLastRH;
      X := Padding.Left;
      W := Width - Padding.Right;
      Dec(J);
    end;
    for I := S to J do begin
      Canvas.FillRect(RectF(X, Y, W, Y + FVerticalSpacing), 0, 0, [], Opacity, FDividerBrush);
      Y := Y + FVerticalSpacing + FLastRH;
    end;
  end;

  // ˮƽ����
  if FHorizontalSpacing > 0 then begin
    J := FLastColumns;
    if not FSpacingBorder then
      Dec(J);
    X := Padding.Left;
    Y := Padding.Top;
    H := Height - Padding.Bottom;
    for I := 0 to J do begin
      if FSpacingBorder then begin
        Canvas.FillRect(RectF(X, Y, X + FHorizontalSpacing, H), 0, 0, [], Opacity, FDividerBrush);
      end else begin
        if (I > 0) then
          Canvas.FillRect(RectF(X - FHorizontalSpacing, Y, X, H), 0, 0, [], Opacity, FDividerBrush);
      end;
      case FLastStretchMode of
        TViewStretchMode.None,
        TViewStretchMode.ColumnWidth:
          begin
            if (J = 1) and (FSpacingBorder) then
              X := Width - Padding.Right - FHorizontalSpacing
            else
              X := X + FHorizontalSpacing + FLastCW;
          end;
        TViewStretchMode.SpacingWidth:
          begin
            if (I = 0) or (I = (J - 1)) then begin
              if FSpacingBorder then
                X := X + FLastCW + (FLastPW + FHorizontalSpacing) * 0.5
              else begin
                if I = 0 then
                  X := X + FLastCW + (FLastPW + FHorizontalSpacing) * 0.5
                else
                  X := X + FLastCW + (FLastPW);
              end;
            end else
              X := X + FLastCW + (FLastPW);
          end;
        TViewStretchMode.SpacingWidthUniform:
          begin
            if J = S + 1 then begin
              X := Width - Padding.Right - FHorizontalSpacing
            end else begin
              if (I = 0) or (I = (J - 1)) then begin
                if FSpacingBorder then
                  X := X + FLastCW + (FLastPW) * 1.5 - FHorizontalSpacing * 0.5
                else begin
                  if I = 0 then
                    X := X + FLastCW + (FLastPW) * 1.5 + FHorizontalSpacing * 0.5
                  else
                    X := X + FLastCW + (FLastPW)
                end;
              end else
                X := X + FLastCW + (FLastPW);
            end;
          end;
      end;
    end;
  end;
end;

function TGridsLayout.GetAbsoluteColumnsNum: Integer;
begin
  if FNumColumns > 0 then
    Result := FNumColumns
  else begin
    if FSpacingBorder then begin
      if FColumnWidth > 0 then
        Result := Trunc((Width - Padding.Left - Padding.Right - FHorizontalSpacing) / (FColumnWidth + FHorizontalSpacing))
      else
        Result := Trunc((Width - Padding.Left - Padding.Right - FHorizontalSpacing) / (CDefaultColumnWidth + FHorizontalSpacing));
    end else begin
      if FColumnWidth > 0 then
        Result := Trunc((Width - Padding.Left - Padding.Right + FHorizontalSpacing) / (FColumnWidth + FHorizontalSpacing))
      else
        Result := Trunc((Width - Padding.Left - Padding.Right + FHorizontalSpacing) / (CDefaultColumnWidth + FHorizontalSpacing));
    end;
  end;
end;

function TGridsLayout.GetCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ControlsCount - 1 do begin
    if not Controls[I].Visible then Continue;
    {$IFDEF MSWINDOWS}
    if IsDesignerControl(Controls[I]) then
      Continue;
    {$ENDIF}
    Inc(Result);
  end;
end;

function TGridsLayout.GetDivider: TAlphaColor;
begin
  Result := FDividerBrush.Color;
end;

function TGridsLayout.IsStoredColumnHeight: Boolean;
begin
  Result := FColumnHeight <> CDefaultColumnHeight;
end;

function TGridsLayout.IsStoredColumnWidth: Boolean;
begin
  Result := FColumnWidth <> CDefaultColumnWidth;
end;

procedure TGridsLayout.PaintBackground;
begin
  inherited PaintBackground;
  if (FLastColumns > 0) and (FLastRows > 0) and (FDividerBrush.Color and $FF000000 <> 0) then
    DrawDivider(Canvas);
end;

procedure TGridsLayout.SetColumnHeight(const Value: Single);
begin
  if FColumnHeight <> Value then begin
    FColumnHeight := Value;
    DoRealign;
  end;
end;

procedure TGridsLayout.SetColumnWidth(const Value: Single);
begin
  if FColumnWidth <> Value then begin
    FColumnWidth := Value;
    DoRealign;
  end;
end;

procedure TGridsLayout.SetDivider(const Value: TAlphaColor);
begin
  if FDividerBrush.Color <> Value then begin
    FDividerBrush.Color := Value;
    Repaint;
  end;
end;

procedure TGridsLayout.SetForceColumnSize(const Value: Boolean);
begin
  if FForceColumnSize <> Value then begin
    FForceColumnSize := Value;
    DoRealign;
  end;
end;

procedure TGridsLayout.SetHorizontalSpacing(const Value: Single);
begin
  if FHorizontalSpacing <> Value then begin
    FHorizontalSpacing := Value;
    DoRealign;
  end;
end;

procedure TGridsLayout.SetNumColumns(const Value: Integer);
begin
  if FNumColumns <> Value then begin
    FNumColumns := Value;
    DoRealign;
    Repaint;
  end;
end;

procedure TGridsLayout.SetSpacingBorder(const Value: Boolean);
begin
  if FSpacingBorder <> Value then begin
    FSpacingBorder := Value;
    DoRealign;
    Repaint;
  end;
end;

procedure TGridsLayout.SetStretchMode(const Value: TViewStretchMode);
begin
  if FStretchMode <> Value then begin
    FStretchMode := Value;
    DoRealign;
    Repaint;
  end;
end;

procedure TGridsLayout.SetVerticalSpacing(const Value: Single);
begin
  if FVerticalSpacing <> Value then begin
    FVerticalSpacing := Value;
    DoRealign;
  end;
end;

{ TDrawableBrush }

constructor TDrawableBrush.Create(AOwner: TComponent);
begin
  FImageLink := TGlyphImageLink.Create(Self);
  FImageLink.OnChange := DoChange;
  inherited Create(AOwner);
  if (csDesigning in ComponentState) then
    CreateBrush(FBrush);
end;

procedure TDrawableBrush.CreateBrush(var Value: TBrush);
begin
  if Assigned(Value) then
    FreeAndNil(Value);
  Value := TViewImagesBrush.Create(TBrushKind.None, TAlphaColorRec.Null);
  TViewImagesBrush(Value).FOwner := Self;
  Value.OnChanged := DoChange;
end;

destructor TDrawableBrush.Destroy;
begin
  FreeAndNil(FBrush);
  FImageLink.DisposeOf;
  inherited Destroy;
end;

procedure TDrawableBrush.DoChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then
    FOnChanged(Sender);
end;

procedure TDrawableBrush.Draw(Canvas: TCanvas; const R: TRectF;
  const XRadius, YRadius: Single; const ACorners: TCorners;
  const AOpacity: Single; const ACornerType: TCornerType);

  procedure DrawImage(const Index: Integer);
  var
    Images: TCustomImageList;
    Bitmap: TBitmap;
    BitmapSize: TSize;
  begin
    Images := GetImages;
    if Assigned(Images) and (Index >= 0) and (Index < Images.Count) then begin
      BitmapSize := TSize.Create(Round(R.Width) * 2, Round(R.Height) * 2);
      if BitmapSize.IsZero then
        Exit;
      Bitmap := Images.Bitmap(BitmapSize, Index);
      if Bitmap <> nil then
        Canvas.DrawBitmap(Bitmap, TRectF.Create(0, 0, Bitmap.Width, Bitmap.Height), R, AOpacity, False);
    end;
  end;

begin
  if (csDestroying in ComponentState) or IsEmpty then Exit;
  if (Ord(FBrush.Kind) = Ord(TViewBrushKind.Patch9Bitmap)) and (FBrush is TViewBrush) then begin
    TDrawableBase.FillRect9Patch(Canvas, R, XRadius, YRadius, ACorners, AOpacity, TViewBrush(FBrush), ACornerType);
  end else
    Canvas.FillRect(R, XRadius, YRadius, ACorners, AOpacity, FBrush, ACornerType);
  if Assigned(FImageLink.Images) and (ImageIndex >= 0) then
    DrawImage(ImageIndex);
end;

function TDrawableBrush.GetBrush: TBrush;
begin
  if not Assigned(FBrush) then
    CreateBrush(FBrush);
  Result := FBrush;
end;

function TDrawableBrush.GetComponent: TComponent;
begin
  Result := Self;
end;

function TDrawableBrush.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

function TDrawableBrush.GetImageIndexEx: TImageIndex;
begin
  Result := TViewImagesBrush(Brush).ImageIndex;
end;

function TDrawableBrush.GetImageList: TBaseImageList;
begin
  Result := GetImages;
end;

function TDrawableBrush.GetImages: TCustomImageList;
begin
  if Assigned(FImageLink.Images) then
    Result := TCustomImageList(FImageLink.Images)
  else
    Result := nil;
end;

function TDrawableBrush.GetIsEmpty: Boolean;
begin
  if ImageIndex >= 0 then
    Result := not Assigned(FImageLink.Images)
  else
    Result := ((FBrush = nil) or (FBrush.Kind = TBrushKind.None));
end;

procedure TDrawableBrush.ImagesChanged;
begin
  DoChange(Self);
end;

procedure TDrawableBrush.SetBrush(const Value: TBrush);
begin
  if (Value = nil) then begin
    FreeAndNil(FBrush);
  end else begin
    if not Assigned(FBrush) then
      CreateBrush(FBrush);
    FBrush.Assign(Value);
  end;
end;

procedure TDrawableBrush.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

procedure TDrawableBrush.SetImageIndexEx(const Value: TImageIndex);
begin
  TViewImagesBrush(Brush).ImageIndex := Value;
end;

procedure TDrawableBrush.SetImageList(const Value: TBaseImageList);
begin
  ValidateInheritance(Value, TCustomImageList);
  SetImages(TCustomImageList(Value));
end;

procedure TDrawableBrush.SetImages(const Value: TCustomImageList);
begin
  FImageLink.Images := Value;
end;

{ TShareImageList }

constructor TShareImageList.Create(AOwner: TComponent);
begin
  inherited;
  if Assigned(Self) and (FShareImageList.IndexOf(Self) < 0) then
    FShareImageList.Add(Self);
end;

destructor TShareImageList.Destroy;
begin
  FShareImageList.Remove(Self);
  inherited;
end;

class function TShareImageList.GetShareImageList: TList<TShareImageList>;
begin
  Result := FShareImageList;
end;

{ TRectFHelper }

procedure TRectFHelper.Clear;
begin
  Left := 0;
  Top := 0;
  Right := 0;
  Bottom := 0;
end;

{ TControlHelper }

procedure TControlHelper.FocusToNext;
var
  I, J, K, M: Integer;
  Item: TControl;
begin
  if not Assigned(Self) then
    Exit;
  K := $FFFFFF;
  J := -1;
  M := TabOrder;
  for I := 0 to ParentControl.ControlsCount - 1 do begin
    Item := ParentControl.Controls[I];
    if (not Assigned(Item)) or (not Item.Visible) or (not Item.Enabled) or (not Item.CanFocus) then
      Continue;
    if (Item.TabOrder < K) and (Item.TabOrder > M) then begin
      K := Item.TabOrder;
      J := I;
    end;
  end;
  if J >= 0 then
    ParentControl.Controls[J].SetFocus;
end;

function TControlHelper.SetFocusObject(V: TControl): Boolean;
var
  Item: TControl;
  I: Integer;
begin
  Result := False;
  for I := 0 to V.ControlsCount - 1 do begin
    Item := V.Controls[I];
    if Item.Visible and (Item.Enabled) and Item.CanFocus then begin
      Item.SetFocus;
      Result := True;
      Break;
    end else if Item.ControlsCount > 0 then begin
      if SetFocusObject(Item) then
        Break;
    end;
  end;
end;

initialization
  FShareImageList := TList<TShareImageList>.Create;
  FAccessoryImages := TViewAccessoryImageList.Create;
  {$IFDEF ANDROID}
  TView.InitAudioManager();
  DoInitFrameStatusHeight();
  DoInitNavigationBarHeight();
  {$ENDIF}

finalization
  {$IFDEF ANDROID}
  FAudioManager := nil;
  {$ENDIF}
  FreeAndNil(FShareImageList);
  FreeAndNil(FAccessoryImages);

end.
