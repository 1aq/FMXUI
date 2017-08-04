unit uFrameVertScrollView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  UI.Frame, UI.Standard, UI.Base, UI.Edit, FMX.Controls.Presentation;

type
  TFrameVertScrollView = class(TFrame)
    LinearLayout1: TLinearLayout;
    tvTitle: TTextView;
    VertScrollView2: TVertScrollView;
    LinearLayout2: TLinearLayout;
    ButtonView2: TButtonView;
    ButtonView3: TButtonView;
    ButtonView4: TButtonView;
    ButtonView7: TButtonView;
    ButtonView9: TButtonView;
    ButtonView10: TButtonView;
    ButtonView11: TButtonView;
    ButtonView12: TButtonView;
    ButtonView13: TButtonView;
    TextView3: TTextView;
    Button2: TButton;
    EditView1: TEditView;
    TextView4: TTextView;
    procedure btnBackClick(Sender: TObject);
    procedure VertScrollView1PullRefresh(Sender: TObject);
    procedure VertScrollView1PullLoad(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

procedure TFrameVertScrollView.btnBackClick(Sender: TObject);
begin
  Finish;
end;

procedure TFrameVertScrollView.VertScrollView1PullLoad(Sender: TObject);
begin
  TFrameAnimator.DelayExecute(Self,
    procedure (Sender: TObject)
    begin
      VertScrollView2.PullLoadComplete;
      Hint('�������');
    end
  , 2);
end;

procedure TFrameVertScrollView.VertScrollView1PullRefresh(Sender: TObject);
begin
  TFrameAnimator.DelayExecute(Self,
    procedure (Sender: TObject)
    begin
      VertScrollView2.PullRefreshComplete;
      Hint('ˢ�����');
    end
  , 3.5);
end;

end.
