
module.exports = (sequelize, DataTypes) ->

  User: sequelize.define "User",
    username:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    first_name: DataTypes.STRING
    last_name: DataTypes.STRING
    email: DataTypes.STRING
    password: DataTypes.STRING
    is_staff:
      type: DataTypes.INTEGER
      default: 0
    is_active:
      type: DataTypes.INTEGER
      default: 1
    is_superuser:
      type: DataTypes.INTEGER
      default: 0
    last_login: DataTypes.DATE
    date_joined: DataTypes.DATE
  ,
    tableName: "auth_user"
    timestamps: false


  Group: sequelize.define "Group",
    name:
      type: DataTypes.STRING
      allowNull: false
      unique: true
  ,
    tableName: "auth_group"
    timestamps: false


  SysUser: sequelize.define "SysUser",
    user_id:
      type: DataTypes.INTEGER
      allowNull: false
      autoIncrement: true
      primaryKey: true

    user_name:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    realname: DataTypes.STRING
    shell: DataTypes.STRING
    password: DataTypes.STRING
    status: DataTypes.STRING
    gid_id: DataTypes.INTEGER
    user: DataTypes.STRING
    hash_method: DataTypes.STRING
    unixpwd: DataTypes.STRING


  SysGroup: sequelize.define "SysGroup",
    group_id:
      type: DataTypes.INTEGER
      allowNull: false
      autoIncrement: true
      primaryKey: true
    group_name:
      type: DataTypes.STRING
      allowNull: false
      unique: true
    status: DataTypes.STRING
  ,
    tableName: "groups"
    timestamps: false

  SysMembership: sequelize.define "SysMembership",
    user: DataTypes.INTEGER
    group: DataTypes.INTEGER
  ,
    tableName: "user_group"
    timestamps: false
