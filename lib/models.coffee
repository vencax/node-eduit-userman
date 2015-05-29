
module.exports = (sequelize, DataTypes) ->

  User: sequelize.define "User",
    username:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    realname: DataTypes.STRING
    email: DataTypes.STRING

    gid:
      type: DataTypes.INTEGER
      allowNull: false

    password: DataTypes.STRING
    status: DataTypes.STRING
    gid_id: DataTypes.INTEGER
    user: DataTypes.STRING
    hash_method: DataTypes.STRING
    unixpwd: DataTypes.STRING
  ,
    tableName: "user"


  Group: sequelize.define "Group",
    name:
      type: DataTypes.STRING
      allowNull: false
      unique: true
    status: DataTypes.STRING
  ,
    tableName: "group"
