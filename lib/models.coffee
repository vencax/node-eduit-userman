
module.exports = (sequelize, DataTypes) ->

  User = sequelize.define "User",
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
    tableName: "users"


  Group = sequelize.define "Group",
    name:
      type: DataTypes.STRING
      allowNull: false
      unique: true
    status: DataTypes.STRING
  ,
    tableName: "groups"


  User.hasMany Group, {through: 'usergroup_mship'}
  Group.hasMany User, {through: 'usergroup_mship'}
  Group.hasOne User, {foreignKey: 'gid' }
