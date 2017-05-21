unit uFrameDialog;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  UI.Frame, UI.Base, FMX.Controls.Presentation, UI.Standard, FMX.Layouts,
  System.ImageList, FMX.ImgList, FMX.Menus, UI.ListView;

type
  TFrmaeDialog = class(TFrame)
    LinearLayout1: TLinearLayout;
    SpeedButton1: TSpeedButton;
    tvTitle: TTextView;
    VertScrollBox1: TVertScrollBox;
    LinearLayout2: TLinearLayout;
    ButtonView1: TButtonView;
    ImageList1: TImageList;
    ButtonView2: TButtonView;
    ButtonView3: TButtonView;
    ButtonView4: TButtonView;
    ButtonView5: TButtonView;
    ButtonView6: TButtonView;
    ButtonView7: TButtonView;
    ButtonView8: TButtonView;
    ButtonView9: TButtonView;
    ButtonView11: TButtonView;
    ButtonView10: TButtonView;
    ButtonView12: TButtonView;
    PopupMenu1: TPopupMenu;
    MenuItem1: TMenuItem;
    procedure SpeedButton1Click(Sender: TObject);
    procedure ButtonView1Click(Sender: TObject);
    procedure ButtonView2Click(Sender: TObject);
    procedure ButtonView3Click(Sender: TObject);
    procedure ButtonView4Click(Sender: TObject);
    procedure ButtonView5Click(Sender: TObject);
    procedure ButtonView6Click(Sender: TObject);
    procedure ButtonView7Click(Sender: TObject);
    procedure ButtonView8Click(Sender: TObject);
    procedure ButtonView9Click(Sender: TObject);
    procedure ButtonView11Click(Sender: TObject);
    procedure ButtonView10Click(Sender: TObject);
    procedure ButtonView12Click(Sender: TObject);
  private
    { Private declarations }
  protected
    // ��ʾ�¼�
    procedure DoShow(); override;
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

uses
  uFrameListViewTest,
  UI.Dialog, UI.Async, uFrameDialog_CustomView;

{ TFrmaeDialog }

procedure TFrmaeDialog.ButtonView10Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .Show;
end;

procedure TFrmaeDialog.ButtonView11Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .SetSingleChoiceItems(
      [
      '�б��� - 1',
      '�б��� - 2',
      '�б��� - 3',
      '�б��� - 4',
      '�б��� - 1',
      '�б��� - 2',
      '�б��� - 3',
      '�б��� - 4',
      '�б��� - 1',
      '�б��� - 2',
      '�б��� - 3',
      '�б��� - 4',
      '�б��� - 1',
      '�б��� - 2',
      '�б��� - 3',
      '�б��� - 4',
      '�б��� - 1',
      '�б��� - 2',
      '�б��� - 3',
      '�б��� - 4',
      '�б��� - 5'
    ], 1)
    .SetPositiveButton('ȡ��')
    .SetNegativeButton('ȷ��',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint('ѡ����: ' + Dialog.Builder.ItemArray[Dialog.Builder.CheckedItem]);
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView12Click(Sender: TObject);
var
  View: TFrameDialogCustomView;
begin
  View := TFrameDialogCustomView.Create(Self);
  TDialogBuilder.Create(Self)
    .SetTitle('��¼')
    .SetView(View)
    .Show;
end;

procedure TFrmaeDialog.ButtonView1Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetMessage('����һ����Ϣ��')
    .Show;
end;

procedure TFrmaeDialog.ButtonView2Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetMessage('����һ����Ϣ��������ʾ��Ϣ����')
    .SetNegativeButton('Negative',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.NegativeButtonText);
      end
    )
    .SetNeutralButton('Neutral',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.NeutralButtonText);
      end
    )
    .SetPositiveButton('Positive',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.PositiveButtonText);
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView3Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .SetMessage('����һ����Ϣ��������ʾ��Ϣ����')
    .SetNegativeButton('Negative',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.NegativeButtonText);
      end
    )
    .SetPositiveButton('Positive',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.PositiveButtonText);
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView4Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .SetItems(['�б��� - 1', '�б��� - 2', '�б��� - 3', '�б��� - 4', '�б��� - 5'],
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Dialog.Builder.ItemArray[Which]);
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView5Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .SetSingleChoiceItems(['�б��� - 1', '�б��� - 2', '�б��� - 3', '�б��� - 4', '�б��� - 5'], 1)
    .SetPositiveButton('ȡ��')
    .SetNegativeButton('ȷ��',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint('ѡ����: ' + Dialog.Builder.ItemArray[Dialog.Builder.CheckedItem]);
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView6Click(Sender: TObject);
begin
  TDialogBuilder.Create(Self)
    .SetTitle('���Ǳ����ı�')
    .SetMultiChoiceItems(['�б��� - 1', '�б��� - 2', '�б��� - 3', '�б��� - 4', '�б��� - 5'], [])
    .SetPositiveButton('ȡ��')
    .SetNegativeButton('ȷ��',
      procedure (Dialog: IDialog; Which: Integer) begin
        Hint(Format('ѡ���� %d ��.', [Dialog.Builder.CheckedCount]));
      end
    )
    .Show;
end;

procedure TFrmaeDialog.ButtonView7Click(Sender: TObject);
begin
  ShowWaitDialog('����ִ������...', False);
  TAsync.Create()
  .SetExecute(
    procedure (Async: TAsync) begin
      Sleep(3000);
    end
  )
  .SetExecuteComplete(
    procedure (Async: TAsync) begin
      HideWaitDialog;
    end
  ).Start;
end;

procedure TFrmaeDialog.ButtonView8Click(Sender: TObject);
begin
  ShowWaitDialog('����ִ������...',
    procedure (Dialog: IDialog) begin
      Hint('����ȡ��');
    end
  );
  TAsync.Create()
  .SetExecute(
    procedure (Async: TAsync) begin
      Sleep(5000);
    end
  )
  .SetExecuteComplete(
    procedure (Async: TAsync) begin
      if not IsWaitDismiss then // �������û�б��ж�
        Hint('����ִ�����.');
      HideWaitDialog;
    end
  ).Start;
end;

procedure TFrmaeDialog.ButtonView9Click(Sender: TObject);
begin
  StartFrame(TFrameListViewTest);
end;

procedure TFrmaeDialog.DoShow;
begin
  inherited;
  tvTitle.Text := Title;
end;

procedure TFrmaeDialog.SpeedButton1Click(Sender: TObject);
begin
  Finish(TFrameAniType.FadeInOut);
end;

end.
