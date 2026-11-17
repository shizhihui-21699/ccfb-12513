class CreateCoreTables < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :phone, null: false
      t.string :email
      t.string :nickname
      t.string :security_question
      t.string :security_answer_digest
      # 账号侧最后一次确认“该手机号仍归本人所有”的时间
      t.datetime :last_phone_confirmed_at, null: false
      t.timestamps
    end
    add_index :users, :phone, unique: true

    # 本地模拟的运营商数据：每个号码当前的入网时间
    create_table :carrier_records do |t|
      t.string :phone, null: false
      t.string :carrier_name, null: false, default: "中国移动"
      t.datetime :activated_at, null: false   # 入网时间（当前持有人的开户时间）
      t.string :status, null: false, default: "in_service" # in_service / cancelled
      t.timestamps
    end
    add_index :carrier_records, :phone, unique: true

    # 短信登录的风控判定记录
    create_table :login_attempts do |t|
      t.references :user, foreign_key: true, null: true
      t.string :phone, null: false
      t.string :decision, null: false         # allowed / blocked
      t.string :reason, null: false           # 判定原因（机器可读）
      t.datetime :carrier_activated_at        # 判定当时查到的入网时间快照
      t.datetime :phone_confirmed_at          # 判定当时账号侧的手机号确认时间快照
      t.string :ip
      t.string :user_agent
      t.timestamps
    end
    add_index :login_attempts, :decision

    # 被拦截后发起的身份核验单
    create_table :verifications do |t|
      t.references :user, foreign_key: true, null: false
      t.references :login_attempt, foreign_key: true, null: false
      t.string :method                                        # email_code / security_question / manual_review
      t.string :status, null: false, default: "pending"       # pending / passed / failed
      t.text :payload                                         # 各核验方式的临时数据（JSON）
      t.text :applicant_note                                  # 人工审核时用户提交的说明
      t.text :admin_note                                      # 运营处理备注
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :verifications, :status
  end
end
